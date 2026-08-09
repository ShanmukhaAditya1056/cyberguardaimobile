/** Port of `lib/core/utils/shap_explainer.dart`. */

export function explainUrl({
  isSuspiciousTld,
  hasKeyword,
  keywords,
  isIpAddress,
  isWhitelisted,
  hasEncoding,
  isLong,
  subdomainCount,
  isMismatch,
}) {
  const reasons = [];

  if (isWhitelisted) {
    return [
      {
        feature: 'Trusted domain whitelist match',
        contribution: 0.85,
        positive: false,
      },
    ];
  }

  if (isIpAddress) {
    reasons.push({
      feature: 'IP address used instead of domain',
      contribution: 0.9,
      positive: true,
    });
  }
  if (isSuspiciousTld) {
    reasons.push({
      feature: 'Suspicious top-level domain',
      contribution: 0.75,
      positive: true,
    });
  }
  if (hasKeyword && keywords.length > 0) {
    reasons.push({
      feature: `Phishing keywords: ${keywords.slice(0, 3).join(', ')}`,
      contribution: 0.8,
      positive: true,
    });
  }
  if (hasEncoding) {
    reasons.push({
      feature: 'URL encoding tricks detected',
      contribution: 0.65,
      positive: true,
    });
  }
  if (isLong) {
    reasons.push({
      feature: 'Excessively long URL (obfuscation)',
      contribution: 0.45,
      positive: true,
    });
  }
  if (subdomainCount > 2) {
    reasons.push({
      feature: `Excessive subdomains (${subdomainCount})`,
      contribution: 0.5,
      positive: true,
    });
  }
  if (isMismatch) {
    reasons.push({
      feature: 'Domain name impersonates trusted brand',
      contribution: 0.88,
      positive: true,
    });
  }

  if (reasons.length === 0) {
    reasons.push({
      feature: 'No known threat patterns detected',
      contribution: 0.2,
      positive: false,
    });
  }

  reasons.sort((a, b) => b.contribution - a.contribution);
  return reasons.slice(0, 5);
}
