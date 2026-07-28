#!/usr/bin/env bash
# Upload iOS-safe re-encode for film 82 test (faststart + ~8 Mbps, not 203 Mbps).
#
# Option A (recommended test): overwrite same S3 key — no DB change, same CloudFront URL
# Option B: upload as new .mp4 and update films.video_url in Supabase manually
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export AWS_REGION=eu-north-1
#
# Usage:
#   ./scripts/upload-film82-ios-safe.sh          # overwrite .mov key (default)
#   ./scripts/upload-film82-ios-safe.sh --new-key  # upload parallel .mp4 key
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="${SCRIPT_DIR}/film82-remux/ios-safe.mp4"
BUCKET="${AWS_S3_BUCKET:-filmila}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-north-1}}"
BASE="1785078208549-vecteezy_seascape-view-time-lapse_1626432"
KEY_MOV="filmmaker/upload/${BASE}.mov"
KEY_MP4="filmmaker/upload/${BASE}-ios-safe.mp4"
CF_DOMAIN="${CLOUDFRONT_PLAYBACK_DOMAIN:-d1mobdm8ed03yd.cloudfront.net}"

if [[ ! -f "$FILE" ]]; then
  echo "Missing $FILE — run re-encode first." >&2
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

MODE="overwrite"
if [[ "${1:-}" == "--new-key" ]]; then
  MODE="new-key"
fi

echo "=== Film 82 iOS-safe upload (~18 MB, 8 Mbps, faststart) ==="
ls -lh "$FILE"
echo

if [[ "$MODE" == "overwrite" ]]; then
  TARGET_KEY="$KEY_MOV"
  CONTENT_TYPE="video/quicktime"
  echo "Mode: overwrite existing .mov at same CloudFront URL (no Supabase change)"
else
  TARGET_KEY="$KEY_MP4"
  CONTENT_TYPE="video/mp4"
  echo "Mode: new object — update films.video_url to:"
  echo "  https://filmila.s3.eu-north-1.amazonaws.com/${TARGET_KEY}"
fi

echo "S3: s3://${BUCKET}/${TARGET_KEY}"
echo

aws s3 cp "$FILE" "s3://${BUCKET}/${TARGET_KEY}" \
  --region "$REGION" \
  --content-type "$CONTENT_TYPE"

echo
echo "CloudFront test URL:"
if [[ "$MODE" == "overwrite" ]]; then
  echo "  https://${CF_DOMAIN}/upload/${BASE}.mov"
else
  echo "  https://${CF_DOMAIN}/upload/${BASE}-ios-safe.mp4"
fi
echo
echo "Invalidate CloudFront after upload:"
if [[ "$MODE" == "overwrite" ]]; then
  echo "  aws cloudfront create-invalidation --distribution-id YOUR_ID --paths \"/upload/${BASE}.mov\""
else
  echo "  aws cloudfront create-invalidation --distribution-id YOUR_ID --paths \"/upload/${BASE}-ios-safe.mp4\""
fi
