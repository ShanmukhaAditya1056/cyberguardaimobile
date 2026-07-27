"""
Train a binary phishing-URL classifier and export the winning model as a
JSON file the Flutter app loads at runtime.

Why JSON, not TFLite?
  TensorFlow does not support Python 3.14 yet (TF caps at 3.12). Rather
  than pin Python, we train with scikit-learn and serialise the learned
  weights to a tiny JSON file. The Dart side runs the forward pass
  directly — no heavyweight runtime needed.

Pipeline
  1.  Procedurally generate ~10 000 labeled URLs: half phishing, half
      legitimate, using real-world templates (Indian banking phishing,
      UPI rewards scams, real brand domains, government portals…).
  2.  For every URL, compute the same 12-feature vector the Flutter
      `PhishingMlService` builds (the contract is shared).
  3.  Train Logistic Regression *and* Random Forest. Pick the higher
      F1 score on a held-out 20 % test split.
  4.  Print confusion matrix, accuracy, precision, recall, F1.
  5.  Export the winner's weights + metadata to
      `assets/models/phishing_weights.json` so the Flutter app can pick
      it up immediately.

Run:
  python ml/train_phishing.py
"""

import json
import math
import os
import random
import re
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.model_selection import train_test_split

random.seed(42)
np.random.seed(42)


# ---------------------------------------------------------------------------
# 1. Dataset generation
# ---------------------------------------------------------------------------

LEGIT_BASES = [
    "https://www.paytm.com/", "https://paytm.com/wallet",
    "https://www.phonepe.com/", "https://phonepe.com/business",
    "https://www.sbi.co.in/", "https://onlinesbi.sbi/personal",
    "https://www.hdfcbank.com/", "https://www.icicibank.com/personal-banking",
    "https://www.axisbank.com/", "https://www.kotak.com/en/home.html",
    "https://www.amazon.in/", "https://www.amazon.in/gp/cart",
    "https://www.flipkart.com/", "https://www.flipkart.com/account",
    "https://www.myntra.com/", "https://www.swiggy.com/",
    "https://www.zomato.com/", "https://www.uber.com/in/",
    "https://www.ola.com/", "https://www.jio.com/",
    "https://www.airtel.in/", "https://www.vi.in/",
    "https://www.irctc.co.in/", "https://www.uidai.gov.in/",
    "https://www.incometax.gov.in/", "https://www.digilocker.gov.in/",
    "https://www.india.gov.in/", "https://www.mygov.in/",
    "https://www.google.com/", "https://mail.google.com/",
    "https://www.youtube.com/", "https://drive.google.com/",
    "https://www.microsoft.com/", "https://login.microsoftonline.com/",
    "https://www.apple.com/", "https://appleid.apple.com/",
    "https://www.linkedin.com/", "https://www.facebook.com/",
    "https://www.instagram.com/", "https://twitter.com/",
    "https://x.com/", "https://www.whatsapp.com/",
    "https://web.whatsapp.com/", "https://www.netflix.com/in/",
    "https://www.spotify.com/in/", "https://www.samsung.com/in/",
    "https://www.truecaller.com/", "https://www.meesho.com/",
    "https://www.dunzo.com/", "https://www.cred.club/",
    "https://www.bookmyshow.com/", "https://www.makemytrip.com/",
    "https://www.goibibo.com/", "https://www.cleartrip.com/",
    "https://www.policybazaar.com/", "https://www.zerodha.com/",
    "https://www.upstox.com/", "https://www.groww.in/",
    "https://www.tatacliq.com/", "https://www.nykaa.com/",
]

LEGIT_PATHS = [
    "", "/", "/login", "/account", "/help", "/about",
    "/products", "/pricing", "/support/contact",
    "/checkout", "/cart", "/orders/history",
    "/category/electronics", "/category/fashion",
    "/blog/security-tips", "/in/security-center",
]

PHISH_BRANDS = [
    "paytm", "phonepe", "gpay", "sbi", "hdfc", "icici", "axis",
    "amazon", "flipkart", "jio", "airtel", "aadhaar", "uidai",
    "npci", "upi", "kotak", "irctc", "digilocker",
]

PHISH_KEYWORDS = [
    "verify-now", "verify-account", "kyc-update", "kyc-verify",
    "aadhaar-verify", "pan-verify", "otp-confirm", "secure-login",
    "upi-reward", "claim-prize", "you-won", "free-jio",
    "sim-block", "tax-refund", "account-suspended",
    "expire-today", "click-now", "free-recharge",
    "blocked", "alert", "notice", "update-details",
    "confirm-details", "reactivate",
]

PHISH_TLDS = [
    ".xyz", ".tk", ".ml", ".ga", ".cf", ".click", ".top",
    ".loan", ".gq", ".pw", ".buzz", ".link", ".site",
    ".online", ".website", ".store",
]


def _legit_url() -> str:
    """Build a legitimate-looking URL by composing real brand bases.

    Includes hard-negative tricks so the model can't trivially separate:
      * Some legit URLs use words like /login, /verify, /update
      * Some carry long campaign tracking query strings
      * Some have several subdomains (mail.beta.support.example.com)
    """
    base = random.choice(LEGIT_BASES).rstrip("/")
    path = random.choice(LEGIT_PATHS)

    # ~25 % use trigger words like /login, /verify, /kyc — legit but matches
    # phishing keyword features.
    if random.random() < 0.25:
        path = "/" + random.choice([
            "login", "login/secure", "account/verify", "account/update",
            "settings/security/otp", "help/recover", "kyc/individual",
            "reward/refer", "wallet/recharge",
        ])

    # ~20 % carry a long benign query string (campaign / referrer / utm).
    if random.random() < 0.20:
        path += (
            "?utm_source=email&utm_medium=banner&utm_campaign="
            + "".join(random.choices("abcdef0123456789", k=24))
        )

    # ~12 % go deep on subdomains.
    if random.random() < 0.12:
        host = re.sub(r"^https?://", "", base).split("/", 1)[0]
        extras = ".".join(random.sample(
            ["mail", "beta", "support", "secure", "api"],
            k=random.randint(1, 3),
        ))
        new_base = base.replace(host, f"{extras}.{host}", 1)
        base = new_base
    return base + path


def _phish_url() -> str:
    """Build a realistic Indian phishing URL.

    Mix of obvious-bad templates and *hard positives* (typo-squatting,
    HTTPS phishing on common TLDs, no brand keyword) so the dataset
    isn't trivially separable.
    """
    brand = random.choice(PHISH_BRANDS)
    keyword = random.choice(PHISH_KEYWORDS)
    tld = random.choice(PHISH_TLDS)

    # Eight templates; the last three are hard positives.
    template = random.choice([
        # Easy templates (~ 65 %)
        f"http://{brand}-{keyword}{tld}/login",
        f"http://secure-{brand}-{keyword}{tld}/index.php",
        f"http://{brand}.{keyword}{tld}/verify",
        f"http://{brand}-india-{keyword}{tld}/auth",
        f"http://{keyword}-{brand}-online{tld}/account",
        f"http://{random.randint(10, 255)}.{random.randint(0, 255)}."
        f"{random.randint(0, 255)}.{random.randint(0, 255)}/{brand}/{keyword}",
        # HARD POSITIVES — HTTPS on a common TLD, no obvious keyword
        f"https://{brand}{random.choice(['x', 'in', 'live'])}.com/account",
        # Typo-squat: paytmm, hdfcc, amazoon
        (
            f"https://{brand}{random.choice(list(brand))}.com/login"
        ),
        # Subdomain spoof: secure.bank.com.evil-host.tk
        f"http://secure.{brand}.com.{random.choice(['evil-host', 'banking-india'])}{tld}/",
    ])

    if random.random() < 0.10:
        template += f"?login=https://{brand}.com@evil"
    if random.random() < 0.12:
        template += "?token=" + "".join(
            random.choices("abcdef0123456789", k=80)
        )
    return template


def make_dataset(n_per_class: int = 5000, label_noise: float = 0.02):
    """Build a balanced labeled URL dataset.

    `label_noise` flips a small fraction of labels at random so the model
    cannot memorise the procedural grammar; this prevents the trivial
    100 % accuracy you get with perfectly clean synthetic data and gives
    a more honest test-set F1.
    """
    rows = []
    for _ in range(n_per_class):
        rows.append((_legit_url(), 0))
    for _ in range(n_per_class):
        rows.append((_phish_url(), 1))
    random.shuffle(rows)
    urls = [r[0] for r in rows]
    labels = np.array([r[1] for r in rows], dtype=np.int64)

    if label_noise > 0:
        flip_mask = np.random.random(len(labels)) < label_noise
        labels = np.where(flip_mask, 1 - labels, labels)

    return urls, labels


# ---------------------------------------------------------------------------
# 2. Feature extraction — MUST match lib/data/services/phishing_ml_service.dart
# ---------------------------------------------------------------------------

SUSPICIOUS_TLDS = (
    ".xyz", ".tk", ".ml", ".ga", ".cf", ".click", ".top",
    ".loan", ".gq", ".pw", ".buzz", ".fun", ".link",
)
PHISHING_WORDS = (
    "login", "verify", "otp", "kyc", "aadhaar",
    "update", "secure", "confirm", "reward", "recharge",
)
BRANDS = (
    "paytm", "phonepe", "gpay", "sbi", "hdfc",
    "icici", "amazon", "flipkart", "jio", "airtel",
)
IP_RE = re.compile(r"^\d{1,3}(?:\.\d{1,3}){3}")
PROTO_RE = re.compile(r"^https?://", re.IGNORECASE)


def featurize(url: str) -> np.ndarray:
    url = url.strip().lower()
    host = PROTO_RE.sub("", url).split("/", 1)[0].split("?", 1)[0]

    has_ip = bool(IP_RE.match(host))
    subdomain_depth = max(0, host.count(".") - 1)

    has_bad_tld = any(host.endswith(t) for t in SUSPICIOUS_TLDS)
    has_phishing_word = any(w in url for w in PHISHING_WORDS)
    has_brand_spoof = any(
        b in url
        and not host.endswith(f"{b}.com")
        and not host.endswith(f"{b}.in")
        for b in BRANDS
    )

    digits = sum(c.isdigit() for c in url)
    digit_ratio = digits / len(url) if url else 0.0
    query_len = len(url.split("?", 1)[1]) if "?" in url else 0

    def clamp01(x: float) -> float:
        return max(0.0, min(1.0, x))

    return np.array([
        clamp01(0.0 if not url else math.log(len(url)) / 8.0),
        clamp01(host.count("-") / 10.0),
        clamp01(host.count(".") / 10.0),
        clamp01(digit_ratio),
        1.0 if "@" in url else 0.0,
        1.0 if has_ip else 0.0,
        1.0 if url.startswith("https://") else 0.0,
        clamp01(subdomain_depth / 5.0),
        1.0 if has_bad_tld else 0.0,
        1.0 if has_phishing_word else 0.0,
        1.0 if has_brand_spoof else 0.0,
        clamp01(query_len / 100.0),
    ], dtype=np.float64)


FEATURE_NAMES = [
    "log_url_length",
    "host_hyphens",
    "host_dots",
    "digit_ratio",
    "has_at_symbol",
    "has_ip_host",
    "uses_https",
    "subdomain_depth",
    "has_suspicious_tld",
    "has_phishing_word",
    "has_brand_spoof",
    "query_length",
]


# ---------------------------------------------------------------------------
# 3. Train + evaluate
# ---------------------------------------------------------------------------

def evaluate(name: str, y_true, y_pred):
    cm = confusion_matrix(y_true, y_pred)
    metrics = {
        "accuracy": accuracy_score(y_true, y_pred),
        "precision": precision_score(y_true, y_pred, zero_division=0),
        "recall": recall_score(y_true, y_pred, zero_division=0),
        "f1": f1_score(y_true, y_pred, zero_division=0),
        "confusion_matrix": cm.tolist(),
    }
    print(f"\n=== {name} ===")
    for k in ("accuracy", "precision", "recall", "f1"):
        print(f"  {k:9s}: {metrics[k]:.4f}")
    tn, fp, fn, tp = cm.ravel()
    print(f"  TN={tn}  FP={fp}  FN={fn}  TP={tp}")
    return metrics


def main():
    print("Generating dataset…")
    urls, labels = make_dataset(n_per_class=5000)
    print(f"  total: {len(urls)} URLs  (positives={int(labels.sum())})")

    print("\nComputing features…")
    X = np.stack([featurize(u) for u in urls])
    y = labels

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42,
    )
    print(f"  train: {len(X_train)}   test: {len(X_test)}")

    # Logistic Regression
    lr = LogisticRegression(
        max_iter=1000, C=1.0, solver="lbfgs", random_state=42,
    )
    lr.fit(X_train, y_train)
    lr_metrics = evaluate("Logistic Regression", y_test, lr.predict(X_test))

    # Random Forest — smaller, leaner than the original so the JSON we
    # ship to the device stays well under 100 KB.
    rf = RandomForestClassifier(
        n_estimators=40, max_depth=5, random_state=42, n_jobs=-1,
    )
    rf.fit(X_train, y_train)
    rf_metrics = evaluate("Random Forest", y_test, rf.predict(X_test))

    # Prefer LR for size unless RF wins by > 2 F1 points. The 12-feature
    # logistic model is ~1 KB; even a small RF is 50 - 100 KB.
    MIN_RF_F1_GAIN = 0.02
    if rf_metrics["f1"] - lr_metrics["f1"] > MIN_RF_F1_GAIN:
        winner_name = "random_forest"
        winner_metrics = rf_metrics
        model_blob = _serialise_rf(rf)
    else:
        winner_name = "logistic_regression"
        winner_metrics = lr_metrics
        model_blob = _serialise_lr(lr)

    print(
        f"\nWinner: {winner_name}  (F1 = {winner_metrics['f1']:.4f}; "
        f"RF needed > +{MIN_RF_F1_GAIN:.2f} F1 to beat LR)"
    )

    # Bundle metadata + weights so the Dart side has everything it needs.
    out = {
        "schema_version": 1,
        "model_type": winner_name,
        "feature_count": len(FEATURE_NAMES),
        "feature_names": FEATURE_NAMES,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "training_samples": int(len(X_train)),
        "test_samples": int(len(X_test)),
        "test_metrics": {
            "accuracy": winner_metrics["accuracy"],
            "precision": winner_metrics["precision"],
            "recall": winner_metrics["recall"],
            "f1": winner_metrics["f1"],
            "confusion_matrix": winner_metrics["confusion_matrix"],
        },
        "all_metrics": {
            "logistic_regression": {
                k: v for k, v in lr_metrics.items() if k != "confusion_matrix"
            },
            "random_forest": {
                k: v for k, v in rf_metrics.items() if k != "confusion_matrix"
            },
        },
        "model": model_blob,
    }

    out_path = (
        Path(__file__).resolve().parent.parent
        / "assets" / "models" / "phishing_weights.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(out, indent=2))
    print(f"\nWrote {out_path}  ({out_path.stat().st_size // 1024} KB)")


def _serialise_lr(lr: LogisticRegression):
    return {
        "kind": "logistic_regression",
        "weights": lr.coef_[0].tolist(),
        "bias": float(lr.intercept_[0]),
    }


def _serialise_rf(rf: RandomForestClassifier):
    """Serialise every tree as a flat list of nodes.

    Each node = {feature, threshold, left, right, value}.
    Leaf nodes have feature=-1 and value=probability of class 1.
    """
    trees = []
    for est in rf.estimators_:
        t = est.tree_
        nodes = []
        for i in range(t.node_count):
            is_leaf = t.children_left[i] == t.children_right[i]
            if is_leaf:
                samples_per_class = t.value[i][0]
                total = samples_per_class.sum()
                p1 = float(samples_per_class[1] / total) if total else 0.0
                nodes.append({
                    "feature": -1,
                    "threshold": 0.0,
                    "left": -1,
                    "right": -1,
                    "value": p1,
                })
            else:
                nodes.append({
                    "feature": int(t.feature[i]),
                    "threshold": float(t.threshold[i]),
                    "left": int(t.children_left[i]),
                    "right": int(t.children_right[i]),
                    "value": 0.0,
                })
        trees.append(nodes)
    return {"kind": "random_forest", "trees": trees}


if __name__ == "__main__":
    main()
