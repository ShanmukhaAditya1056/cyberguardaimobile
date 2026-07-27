"""
02_prepare_phishing_data.py
Reads data/raw/phishing_urls.csv + safe_urls.csv, computes 25 URL
features per row, splits 80/20 stratified, writes the processed
train/test CSVs.

The 25 features must stay in sync with both:
  * scripts/03_train_distilbert.py (uses raw URL strings)
  * scripts/05_train_random_forest.py / 06_train_lightgbm.py (use these features)
  * lib/data/services/phishing_ml_service.dart (Dart-side inference)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import urlparse

import pandas as pd
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
PROC = ROOT / "data" / "processed"
PROC.mkdir(parents=True, exist_ok=True)

DANGEROUS_TLDS = (
    ".xyz", ".tk", ".ml", ".ga", ".cf", ".click", ".top",
    ".work", ".loan", ".gq", ".pw", ".buzz", ".fun",
)
SAFE_TLDS = (".com", ".in", ".co.in", ".gov.in", ".org", ".net", ".edu")
BANK_KW = ("hdfc", "sbi", "icici", "axis", "kotak", "paytm",
           "phonepe", "gpay", "upi", "bank")
VERIFY_KW = ("verify", "login", "update", "confirm",
             "secure", "alert", "urgent", "block")
INDIA_SCAM_KW = ("kyc", "aadhaar", "pan", "trai", "jio", "recharge",
                 "cashback", "reward", "prize", "winner")
ACTION_KW = ("click-now", "act-now", "limited-time",
             "expire", "suspended", "locked")
SHORTENERS = ("bit.ly", "tinyurl", "t.co", "goo.gl", "ow.ly")
BRANDS = ("paytm", "phonepe", "gpay", "sbi", "hdfc", "icici",
          "amazon", "flipkart", "jio", "airtel")
IP_RE = re.compile(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
SPECIAL_CHARS = set("!#$%^&*")


def extract_domain(url: str) -> str:
    parsed = urlparse(url if url.startswith(("http://", "https://"))
                      else f"http://{url}")
    return parsed.netloc or url.split("/", 1)[0]


def check_brand_spoof(url_lower: str) -> bool:
    for b in BRANDS:
        if b in url_lower:
            host = extract_domain(url_lower)
            if not host.endswith(f"{b}.com") and not host.endswith(f"{b}.in"):
                return True
    return False


def extract_url_features(url: str, label: int) -> dict:
    url_lower = url.lower().strip()
    domain = extract_domain(url_lower)
    return {
        "url_length": len(url),
        "domain_length": len(domain),
        "path_length": max(0, len(url) - len(domain)),
        "num_dots": url_lower.count("."),
        "num_hyphens": url_lower.count("-"),
        "num_underscores": url_lower.count("_"),
        "num_slashes": url_lower.count("/"),
        "num_at": url_lower.count("@"),
        "num_params": url_lower.count("?"),
        "num_digits": sum(c.isdigit() for c in url),
        "num_special": sum(c in SPECIAL_CHARS for c in url),
        "has_https": int(url_lower.startswith("https")),
        "has_ip": int(bool(IP_RE.search(url))),
        "has_at_symbol": int("@" in url),
        "is_shortened": int(any(s in url_lower for s in SHORTENERS)),
        "is_dangerous_tld": int(any(url_lower.endswith(t) or f"{t}/" in url_lower
                                    for t in DANGEROUS_TLDS)),
        "is_safe_tld": int(any(url_lower.endswith(t) for t in SAFE_TLDS)),
        "has_bank_keyword": int(any(k in url_lower for k in BANK_KW)),
        "has_verify_keyword": int(any(k in url_lower for k in VERIFY_KW)),
        "has_india_scam_keyword":
            int(any(k in url_lower for k in INDIA_SCAM_KW)),
        "has_action_keyword": int(any(k in url_lower for k in ACTION_KW)),
        "keyword_count": sum(1 for k in (
            *VERIFY_KW, *INDIA_SCAM_KW, "free", "claim") if k in url_lower),
        "num_subdomains": max(0, len(domain.split(".")) - 1),
        "domain_has_digit":
            int(any(c.isdigit() for c in domain.split(".")[0])),
        "has_brand_spoof": int(check_brand_spoof(url_lower)),
        "label": label,
    }


def main() -> int:
    print("=" * 60)
    print(" 02_prepare_phishing_data — start")
    print("=" * 60)

    phish_csv = RAW / "phishing_urls.csv"
    safe_csv = RAW / "safe_urls.csv"
    if not phish_csv.exists() or not safe_csv.exists():
        print("[02] Run 01_collect_data.py first.", file=sys.stderr)
        return 1

    p = pd.read_csv(phish_csv)
    s = pd.read_csv(safe_csv)
    print(f"[02] phishing rows={len(p)}  safe rows={len(s)}")

    frames = []
    for df, label in ((p, 1), (s, 0)):
        for _, row in df.iterrows():
            frames.append(extract_url_features(str(row["url"]), label))
    out = pd.DataFrame(frames)
    print(f"[02] features computed: shape={out.shape}")
    print(out["label"].value_counts().rename("class_distribution"))

    train, test = train_test_split(
        out, test_size=0.20, stratify=out["label"], random_state=42)
    train.to_csv(PROC / "phishing_train.csv", index=False)
    test.to_csv(PROC / "phishing_test.csv", index=False)
    print(f"[02] wrote train={len(train)}  test={len(test)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
