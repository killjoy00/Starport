#!/usr/bin/env bash
# Rebuild StarPort's universal icon from the approved gateway artwork.
# The source JPEG is committed to the repo; the generated 1024px PNG is committed too.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
icons="$repo_root/Starport/Assets.xcassets/AppIcon.appiconset"
source="$icons/ApprovedGateway.jpg"
target="$icons/AppIcon.png"
test -s "$source"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sips -s format png "$source" --out "$tmp/source.png" >/dev/null
sips -z 1024 1024 "$tmp/source.png" --out "$target" >/dev/null
height="$(sips -g pixelHeight "$target" | awk '/pixelHeight:/ {print $2}')"
width="$(sips -g pixelWidth "$target" | awk '/pixelWidth:/ {print $2}')"
if [ "$height" != "1024" ] || [ "$width" != "1024" ]; then
  echo "::error::AppIcon.png is not 1024x1024"
  exit 1
fi
echo "Rebuilt the approved StarPort gateway icon: $width x $height."
