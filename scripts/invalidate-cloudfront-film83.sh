#!/usr/bin/env bash
# Invalidate CloudFront cache for film 83 playback path after S3 overwrite.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export CLOUDFRONT_DISTRIBUTION_ID=E1234567890   # filmila-upload user may lack CloudFront perms
#
# Usage:
#   ./scripts/invalidate-cloudfront-film83.sh
# Or invalidate in AWS Console: path /upload/1785078761506-vecteezy_time-lapse-landscape-sunset-with-twilight-fluffy-cloud-sky_5245026.mp4
set -euo pipefail

CF_DOMAIN="${CLOUDFRONT_PLAYBACK_DOMAIN:-d1mobdm8ed03yd.cloudfront.net}"
BASE="1785078761506-vecteezy_time-lapse-landscape-sunset-with-twilight-fluffy-cloud-sky_5245026"
PATH_TO_INVALIDATE="/upload/${BASE}.mp4"

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

DIST_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"
if [[ -z "$DIST_ID" ]]; then
  echo "Looking up CloudFront distribution for ${CF_DOMAIN}..."
  DIST_ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?DomainName=='${CF_DOMAIN}'].Id | [0]" --output text)"
  if [[ -z "$DIST_ID" || "$DIST_ID" == "None" ]]; then
    echo "Could not find distribution. Set CLOUDFRONT_DISTRIBUTION_ID or invalidate in AWS Console:" >&2
    echo "  Path: ${PATH_TO_INVALIDATE}" >&2
    exit 1
  fi
fi

echo "Distribution: ${DIST_ID}"
echo "Invalidating: ${PATH_TO_INVALIDATE}"
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "$PATH_TO_INVALIDATE"

echo
echo "Verify when complete (expect content-length: 20634804):"
echo "  curl -sI \"https://${CF_DOMAIN}${PATH_TO_INVALIDATE}\" | grep -i content-length"
