#!/usr/bin/env bash
# Invalidate CloudFront cache for film 82 playback path after S3 overwrite.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export AWS_REGION=eu-north-1
#   export CLOUDFRONT_DISTRIBUTION_ID=E1234567890   # or leave unset to auto-discover by domain
#
# Usage:
#   ./scripts/invalidate-cloudfront-film82.sh
set -euo pipefail

CF_DOMAIN="${CLOUDFRONT_PLAYBACK_DOMAIN:-d1mobdm8ed03yd.cloudfront.net}"
BASE="1785078208549-vecteezy_seascape-view-time-lapse_1626432"
PATH_TO_INVALIDATE="/upload/${BASE}.mov"

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

DIST_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"
if [[ -z "$DIST_ID" ]]; then
  echo "Looking up CloudFront distribution for ${CF_DOMAIN}..."
  DIST_ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='${CF_DOMAIN}'].Id | [0]" --output text)"
  if [[ -z "$DIST_ID" || "$DIST_ID" == "None" ]]; then
    echo "Could not find distribution for ${CF_DOMAIN}. Set CLOUDFRONT_DISTRIBUTION_ID." >&2
    exit 1
  fi
fi

echo "Distribution: ${DIST_ID}"
echo "Invalidating: ${PATH_TO_INVALIDATE}"
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "$PATH_TO_INVALIDATE"

echo
echo "Verify when complete (expect content-length ~18889443):"
echo "  curl -sI \"https://${CF_DOMAIN}${PATH_TO_INVALIDATE}\" | grep -i content-length"
