"""
01_collect_data.py
Collects raw URL + Wi-Fi training data into ml_training/data/raw/.

PHISHING:
  * Try the PhishTank public feed first.
  * Fall back to a curated Indian phishing seed list if the feed is
    unreachable (PhishTank now gates downloads behind a key).

SAFE:
  * Hardcoded list of real Indian + global legitimate domains.

WIFI:
  * Synthetic but realistic 'normal network' samples for one-class
    Isolation Forest training.
"""

from __future__ import annotations

import csv
import gzip
import io
import json
import os
import random
import sys
from pathlib import Path

import pandas as pd
import requests

random.seed(42)

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
RAW.mkdir(parents=True, exist_ok=True)

INDIAN_PHISHING_SEED = [
    "secure-hdfc-login.verify-now.xyz/update",
    "sbi-alert-kyc.account-verify.tk/login",
    "paytm-kyc-update.upi-link.ml/verify",
    "aadhaar-verify.gov-india.cf/update",
    "trai-notice-urgent.action-required.xyz",
    "free-jio-data.claim-now.tk/redeem",
    "upi-reward-claim.prize-winner.xyz",
    "hdfc-secure-login.verify-account.top",
    "sbi-net-banking.login-update.work",
    "income-tax-refund.claim-prize.xyz",
    "pm-kisan-portal.gov-scheme.ml",
    "icici-bank-alert.account-blocked.xyz",
    "axis-bank-verify.urgent-action.tk",
    "phonepe-blocked.verify-now.xyz/kyc",
    "gpay-reward.upi-cashback.ml/claim",
    "corona-relief-fund.claim-now.cf",
    "epf-withdrawal-online.verify.xyz",
    "lic-premium-due.payment-link.tk",
    "amazon-lucky-winner.prize-claim.xyz",
    "flipkart-offer-claim.free-gift.ml",
    "sim-block-trai.immediate-action.xyz",
    "whatsapp-account-suspended.verify.tk",
    "facebook-security-alert.login.xyz",
    "bitcoin-investment-india.profit.ml",
    "mutual-fund-claim.return-now.xyz",
]

SAFE_DOMAINS = [
    "https://www.google.com", "https://www.google.co.in",
    "https://www.youtube.com", "https://www.gmail.com",
    "https://www.paytm.com", "https://www.phonepe.com",
    "https://www.sbi.co.in", "https://www.onlinesbi.sbi",
    "https://www.hdfcbank.com", "https://www.icicibank.com",
    "https://www.axisbank.com", "https://www.amazon.in",
    "https://www.flipkart.com", "https://www.myntra.com",
    "https://www.swiggy.com", "https://www.zomato.com",
    "https://www.irctc.co.in", "https://www.uidai.gov.in",
    "https://www.incometax.gov.in", "https://www.digilocker.gov.in",
    "https://www.mygov.in", "https://www.jio.com",
    "https://www.airtel.in", "https://www.vi.in",
    "https://www.bsnl.co.in", "https://www.instagram.com",
    "https://www.facebook.com", "https://www.twitter.com",
    "https://www.linkedin.com", "https://www.whatsapp.com",
    "https://www.netflix.com", "https://www.spotify.com",
    "https://www.microsoft.com", "https://www.apple.com",
    "https://www.samsung.com", "https://www.truecaller.com",
    "https://www.ola.com", "https://www.uber.com",
    "https://www.meesho.com", "https://www.npci.org.in",
    "https://www.bhimupi.org.in", "https://www.kotak.com",
    "https://www.yesbank.in", "https://www.pnbindia.in",
    "https://www.bankofbaroda.in", "https://www.canarabank.com",
]

PHISHTANK_URL = "http://data.phishtank.com/data/online-valid.json.gz"


def fetch_phishtank() -> list[str]:
    try:
        print(f"[01] Trying PhishTank feed {PHISHTANK_URL}")
        resp = requests.get(PHISHTANK_URL, timeout=30,
                            headers={"User-Agent": "CyberGuard-Training/1.0"})
        resp.raise_for_status()
        with gzip.GzipFile(fileobj=io.BytesIO(resp.content)) as gz:
            payload = json.loads(gz.read().decode("utf-8", errors="ignore"))
        urls = [row["url"] for row in payload if "url" in row]
        print(f"[01] PhishTank: got {len(urls)} URLs")
        return urls
    except Exception as exc:
        print(f"[01] PhishTank feed unavailable ({exc}); using seed list.")
        return []


def generate_phishing_variants(base: list[str], target: int) -> list[str]:
    """Expand the seed list to ~target rows by remixing tokens."""
    brands = ["sbi", "hdfc", "icici", "axis", "paytm", "phonepe", "gpay",
              "jio", "airtel", "kotak", "yesbank", "pnb", "bob",
              "amazon", "flipkart", "irctc", "trai", "aadhaar", "uidai"]
    actions = ["verify", "update", "kyc", "login", "secure", "claim",
               "reward", "alert", "block", "suspend", "free", "win"]
    tlds = [".xyz", ".tk", ".ml", ".ga", ".cf", ".click", ".top",
            ".work", ".loan", ".pw", ".buzz", ".fun"]
    out = list(base)
    while len(out) < target:
        b, a1, a2 = random.choice(brands), random.choice(actions), random.choice(actions)
        t = random.choice(tlds)
        out.append(f"http://{b}-{a1}-now.{a2}-india{t}/login")
    return out[:target]


def write_phishing(urls: list[str]) -> None:
    path = RAW / "phishing_urls.csv"
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["url", "label"])
        for u in urls:
            w.writerow([u, 1])
    print(f"[01] Wrote {path} ({len(urls)} rows)")


def write_safe(urls: list[str]) -> None:
    path = RAW / "safe_urls.csv"
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["url", "label"])
        for u in urls:
            w.writerow([u, 0])
    print(f"[01] Wrote {path} ({len(urls)} rows)")


def write_wifi(n: int = 300) -> None:
    path = RAW / "wifi_readings.csv"
    rows = []
    for _ in range(n):
        rows.append({
            "rssi": random.randint(-75, -25),
            "encryption_code": random.choice([2, 3]),  # WPA2 / WPA3
            "is_public": random.choice([0, 0, 0, 1]),
            "dns_response_ms": random.randint(5, 80),
            "beacon_interval": 100,
            "bssid_changes": random.choice([0, 0, 0, 0, 1]),
            "rssi_variance": round(random.uniform(0.5, 4.0), 2),
            "frequency_ghz": random.choice([2.4, 5.0]),
        })
    pd.DataFrame(rows).to_csv(path, index=False)
    print(f"[01] Wrote {path} ({n} rows)")


def main() -> int:
    print("=" * 60)
    print(" 01_collect_data — start")
    print("=" * 60)
    try:
        feed = fetch_phishtank()
        urls = feed + INDIAN_PHISHING_SEED
        urls = generate_phishing_variants(urls, target=max(10000, len(urls)))
        write_phishing(urls)
        write_safe(SAFE_DOMAINS * 100)  # repeat for class balance
        write_wifi(300)
        print(f"[01] DONE  phishing={len(urls)}  safe={len(SAFE_DOMAINS)*100}  wifi=300")
        return 0
    except Exception as exc:
        print(f"[01] FAILED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
