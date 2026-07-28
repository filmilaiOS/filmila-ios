#!/usr/bin/env bash
# Overwrite film 82 on S3 with the faststart-remuxed copy (same key, same codec).
#
# Prerequisites:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export AWS_REGION=eu-north-1   # optional, default eu-north-1
#
# Usage:
#   ./scripts/upload-film82-faststart.sh
#
# After upload, invalidate CloudFront (optional but recommended for immediate test):
#   aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/upload/1785078208549-vecteezy_seascape-view-time-lapse_1626432.mov"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="${SCRIPT_DIR}/film82-remux/faststart.mov"
BUCKET="${AWS_S3_BUCKET:-filmila}"
KEY="filmmaker/upload/1785078208549-vecteezy_seascape-view-time-lapse_1626432.mov"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-north-1}}"

if [[ ! -f "$FILE" ]]; then
  echo "Missing remuxed file: $FILE" >&2
  echo "Run remux first (see scripts/film82-remux/ or re-run download+ffmpeg)." >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found. Install: brew install awscli" >&2
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY before running." >&2
  exit 1
fi

echo "=== Uploading faststart remux ==="
echo "Local:  $FILE ($(ls -lh "$FILE" | awk '{print $5}'))"
echo "S3:     s3://${BUCKET}/${KEY}"
echo "Region: $REGION"
echo

aws s3 cp "$FILE" "s3://${BUCKET}/${KEY}" \
  --region "$REGION" \
  --content-type video/quicktime \
  --metadata-directive REPLACE

echo
echo "=== CloudFront playback URL (unsigned test) ==="
echo "https://d1mobdm8ed03yd.cloudfront.net/upload/1785078208549-vecteezy_seascape-view-time-lapse_1626432.mov"
echo
echo "No Supabase video_url change needed — same object key."
echo "If CloudFront serves a stale copy, create an invalidation for the path above."
