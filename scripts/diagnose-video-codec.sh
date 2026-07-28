#!/usr/bin/env bash
# Probe a Filmila playback file (local path or presigned HTTPS URL) for iOS AVFoundation compatibility.
# Usage:
#   ./scripts/diagnose-video-codec.sh /path/to/file.mp4
#   ./scripts/diagnose-video-codec.sh "https://filmila.s3.../file.mp4?X-Amz-..."
set -euo pipefail

INPUT="${1:?Usage: $0 <local-file-or-presigned-url>}"

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "ffprobe not found. Install: brew install ffmpeg"
  exit 1
fi

echo "=== Input ==="
echo "$INPUT"
echo

echo "=== Video stream ==="
ffprobe -hide_banner -v error -select_streams v:0 \
  -show_entries stream=codec_name,codec_long_name,profile,pix_fmt,level,width,height,r_frame_rate,bit_rate,codec_tag_string \
  -of default=noprint_wrappers=1 "$INPUT"

echo
echo "=== Audio stream ==="
ffprobe -hide_banner -v error -select_streams a:0 \
  -show_entries stream=codec_name,profile,sample_rate,channels,bit_rate \
  -of default=noprint_wrappers=1 "$INPUT" || echo "(no audio stream)"

echo
echo "=== Container / faststart hint ==="
ffprobe -hide_banner -v error \
  -show_entries format=format_name,format_long_name,duration,size,bit_rate \
  -of default=noprint_wrappers=1 "$INPUT"

echo
echo "=== iOS compatibility notes ==="
CODEC=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT")
PROFILE=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=profile -of csv=p=0 "$INPUT")
PIX=$(ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$INPUT")

case "$CODEC" in
  h264)
    echo "- Video: H.264 ($PROFILE, $PIX)"
    if [[ "$PIX" != "yuv420p" ]]; then
      echo "  WARN: iOS AVPlayer expects yuv420p for broad H.264 support. Re-encode recommended."
    fi
    if [[ "$PROFILE" == *"444"* ]]; then
      echo "  WARN: High 4:4:4 profiles often trigger VTDecoder BadData on iOS."
    fi
    ;;
  hevc|h265)
    echo "- Video: HEVC ($PROFILE, $PIX)"
    echo "  NOTE: HEVC works on physical devices (A9+); Simulator support varies. Prefer H.264 for catalog masters."
    ;;
  *)
    echo "- Video: $CODEC ($PROFILE, $PIX)"
    echo "  WARN: Non H.264/HEVC may fail in AVPlayer. Re-encode to H.264 High + yuv420p."
    ;;
esac

echo
echo "=== Suggested iOS-safe re-encode ==="
cat <<'EOF'
ffmpeg -i INPUT.mov \
  -c:v libx264 -profile:v high -level 4.1 -pix_fmt yuv420p \
  -preset medium -crf 20 -g 60 -keyint_min 60 \
  -movflags +faststart \
  -c:a aac -b:a 128k -ar 48000 -ac 2 \
  OUTPUT-ios.mp4
EOF
