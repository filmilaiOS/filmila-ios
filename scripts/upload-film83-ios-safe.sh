#!/usr/bin/env bash
# Upload iOS-safe re-encode for film 83 (free test film).
# Overwrites same S3 key — no DB change, same CloudFront URL.
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export AWS_REGION=eu-north-1
#
# Usage:
#   ./scripts/upload-film83-ios-safe.sh
#   ./scripts/invalidate-cloudfront-film83.sh   # requires CloudFront IAM or console
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="${SCRIPT_DIR}/film83-remux/ios-safe.mp4"
BUCKET="${AWS_S3_BUCKET:-filmila}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-north-1}}"
BASE="1785078761506-vecteezy_time-lapse-landscape-sunset-with-twilight-fluffy-cloud-sky_5245026"
KEY="filmmaker/upload/${BASE}.mp4"
CF_DOMAIN="${CLOUDFRONT_PLAYBACK_DOMAIN:-d1mobdm8ed03yd.cloudfront.net}"

if [[ ! -f "$FILE" ]]; then
  echo "Missing $FILE — download original and re-encode first." >&2
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

echo "=== Film 83 iOS-safe upload ==="
ls -lh "$FILE"
stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE"
echo "S3: s3://${BUCKET}/${KEY}"
echo

aws s3 cp "$FILE" "s3://${BUCKET}/${KEY}" \
  --region "$REGION" \
  --content-type "video/mp4"

echo
echo "CloudFront URL (invalidate after upload):"
echo "  https://${CF_DOMAIN}/upload/${BASE}.mp4"
echo
echo "Verify:"
echo "  curl -sI \"https://${CF_DOMAIN}/upload/${BASE}.mp4\" | grep -i content-length"
echo "  (expect content-length: 20634804 after invalidation)"
