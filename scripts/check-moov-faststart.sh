#!/usr/bin/env bash
# Detect whether an MP4/MOV has the moov atom before mdat (faststart / web-optimized).
# Works on local files or HTTPS URLs (presigned S3 GET supports Range).
#
# Usage:
#   ./scripts/check-moov-faststart.sh /path/to/file.mov
#   ./scripts/check-moov-faststart.sh "https://filmila.s3.../file.mov?X-Amz-..."
set -euo pipefail

INPUT="${1:?Usage: $0 <local-file-or-https-url>}"

WORKDIR="${TMPDIR:-/tmp}/filmila-moov-$$"
mkdir -p "$WORKDIR"
trap 'rm -rf "$WORKDIR"' EXIT

fetch_range() {
  local url="$1" start="$2" end="$3" out="$4"
  curl -sS -f -L --range "${start}-${end}" "$url" -o "$out"
}

head_bytes() {
  local url="$1" count="$2" out="$3"
  curl -sS -f -L --range "0-$((count - 1))" "$url" -o "$out"
}

tail_bytes() {
  local url="$1" count="$2" out="$3"
  local size
  size=$(curl -sS -f -L -I "$url" | awk 'tolower($1)=="content-length:" {print $2}' | tr -d '\r')
  if [[ -z "$size" || ! "$size" =~ ^[0-9]+$ ]]; then
    echo "Could not read Content-Length for URL" >&2
    return 1
  fi
  local start=$((size - count))
  if (( start < 0 )); then start=0; fi
  fetch_range "$url" "$start" "$((size - 1))" "$out"
  echo "$size"
}

atom_scan() {
  python3 - "$1" <<'PY'
import struct, sys
path = sys.argv[1]
data = open(path, 'rb').read()
offset = 0
atoms = []
while offset + 8 <= len(data):
    size = struct.unpack('>I', data[offset:offset+4])[0]
    typ = data[offset+4:offset+8].decode('latin1', errors='replace')
    if size < 8:
        break
    atoms.append((offset, typ, size))
    if size == 0:
        break
    offset += size
    if offset > len(data):
        break
for off, typ, size in atoms:
    print(f"  offset={off:8d}  type={typ!r:4s}  size={size}")
moov = [a for a in atoms if a[1] == 'moov']
mdat = [a for a in atoms if a[1] == 'mdat']
if moov and mdat:
    if moov[0][0] < mdat[0][0]:
        print("RESULT=faststart (moov before mdat in scanned window)")
    else:
        print("RESULT=NOT faststart (mdat before moov in scanned window)")
elif moov:
    print("RESULT=moov present (mdat not in scanned window — likely faststart if moov is near start)")
else:
    print("RESULT=moov not in scanned window (may be at end of file — NOT faststart)")
PY
}

echo "=== Input ==="
echo "$INPUT"
echo

if [[ "$INPUT" == http* ]]; then
  echo "=== Remote HEAD ==="
  curl -sS -I -L "$INPUT" | awk 'tolower($0) ~ /^(http|content-length|content-type|accept-ranges)/ {print}'
  echo

  HEAD_FILE="$WORKDIR/head.bin"
  TAIL_FILE="$WORKDIR/tail.bin"
  echo "=== First 256 KiB atom scan ==="
  head_bytes "$INPUT" $((256 * 1024)) "$HEAD_FILE"
  atom_scan "$HEAD_FILE"
  echo

  echo "=== Last 256 KiB atom scan ==="
  FILE_SIZE=$(tail_bytes "$INPUT" $((256 * 1024)) "$TAIL_FILE")
  echo "  file_size=$FILE_SIZE bytes"
  atom_scan "$TAIL_FILE"
  echo

  if command -v ffprobe >/dev/null 2>&1; then
    echo "=== ffprobe (stream + format) ==="
    ffprobe -hide_banner -v error -select_streams v:0 \
      -show_entries stream=codec_name,profile,pix_fmt,width,height,r_frame_rate,bit_rate \
      -show_entries format=format_name,duration,size,bit_rate \
      -of default=noprint_wrappers=1 "$INPUT" || echo "(ffprobe failed — URL may have expired)"
  fi
else
  echo "=== Local file size ==="
  ls -lh "$INPUT"
  echo

  HEAD_FILE="$WORKDIR/local-head.bin"
  dd if="$INPUT" of="$HEAD_FILE" bs=262144 count=1 status=none 2>/dev/null || cp "$INPUT" "$HEAD_FILE"
  echo "=== First 256 KiB atom scan ==="
  atom_scan "$HEAD_FILE"
  echo

  FILE_SIZE=$(stat -f%z "$INPUT" 2>/dev/null || stat -c%s "$INPUT")
  TAIL_FILE="$WORKDIR/local-tail.bin"
  START=$((FILE_SIZE - 262144))
  if (( START < 0 )); then START=0; fi
  dd if="$INPUT" of="$TAIL_FILE" bs=1 skip="$START" status=none 2>/dev/null
  echo "=== Last 256 KiB atom scan (file_size=$FILE_SIZE) ==="
  atom_scan "$TAIL_FILE"
  echo

  if command -v ffprobe >/dev/null 2>&1; then
    echo "=== ffprobe ==="
    ffprobe -hide_banner -v error -select_streams v:0 \
      -show_entries stream=codec_name,profile,pix_fmt,width,height,r_frame_rate,bit_rate \
      -show_entries format=format_name,duration,size,bit_rate \
      -of default=noprint_wrappers=1 "$INPUT"
  fi

  if command -v qt-faststart >/dev/null 2>&1; then
    echo
    echo "=== qt-faststart probe ==="
    OUT="$WORKDIR/qt-faststart-out.mov"
    if qt-faststart "$INPUT" "$OUT" 2>&1; then
      if cmp -s "$INPUT" "$OUT"; then
        echo "qt-faststart: already optimized (output identical)"
      else
        echo "qt-faststart: moov was relocated (file was NOT faststart)"
      fi
    else
      echo "qt-faststart: could not process file"
    fi
  fi
fi

echo
echo "=== Interpretation ==="
cat <<'EOF'
- moov before mdat at file start → faststart; AVPlayer can begin progressive download immediately.
- moov only in tail scan → classic non-faststart MOV/MP4; AVPlayer must fetch the end of the file
  before decoding, which often triggers AVPlayerItemPlaybackStalled on large objects even on fast WiFi.
- Refreshing a presigned URL does not change atom layout; re-signing the same S3 object will not fix this.
EOF
