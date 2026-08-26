#!/bin/bash
# Full cache-busting Flutter web build script
# Renames main.dart.js, flutter.js, and flutter_service_worker.js with timestamps
# so browsers are forced to download the new version on every deploy.

set -e

echo "🚀 Building Flutter Web Release..."
flutter build web --release --pwa-strategy=none --no-web-resources-cdn -O4

TIMESTAMP=$(date +%s)
BUILD="build/web"

# macOS uses BSD sed (-i ''), Linux uses GNU sed (-i)
if [[ "$OSTYPE" == "darwin"* ]]; then
  SI() { sed -i '' "$@"; }
else
  SI() { sed -i "$@"; }
fi

echo "🧹 Cache-busting version: $TIMESTAMP"

# ── 1. Rename main.dart.js ────────────────────────────────────────────────────
if [ -f "$BUILD/main.dart.js" ]; then
  NEW_MAIN="main.dart.$TIMESTAMP.js"
  mv "$BUILD/main.dart.js" "$BUILD/$NEW_MAIN"
  # Update flutter_bootstrap.js to reference the new filename
  SI "s/main\.dart\.js/$NEW_MAIN/g" "$BUILD/flutter_bootstrap.js"
  echo "  ✓ main.dart.js → $NEW_MAIN"
fi

# ── 2. Rename flutter.js (if present) ────────────────────────────────────────
if [ -f "$BUILD/flutter.js" ]; then
  NEW_FLUTTER="flutter.$TIMESTAMP.js"
  mv "$BUILD/flutter.js" "$BUILD/$NEW_FLUTTER"
  SI "s/\"flutter\.js\"/\"$NEW_FLUTTER\"/g" "$BUILD/flutter_bootstrap.js"
  SI "s/'flutter\.js'/'$NEW_FLUTTER'/g"     "$BUILD/flutter_bootstrap.js"
  echo "  ✓ flutter.js → $NEW_FLUTTER"
fi

# ── 3. Rename service worker (prevents old SW intercepting new build) ─────────
if [ -f "$BUILD/flutter_service_worker.js" ]; then
  NEW_SW="flutter_service_worker.$TIMESTAMP.js"
  mv "$BUILD/flutter_service_worker.js" "$BUILD/$NEW_SW"
  SI "s/flutter_service_worker\.js/$NEW_SW/g" "$BUILD/flutter_bootstrap.js"
  echo "  ✓ flutter_service_worker.js → $NEW_SW"
fi

# ── 4. Bust flutter_bootstrap.js reference in index.html ─────────────────────
SI "s/flutter_bootstrap\.js/flutter_bootstrap.js?v=$TIMESTAMP/g" "$BUILD/index.html"
echo "  ✓ index.html bootstrap reference busted"

echo ""
echo "✅ Build complete in $BUILD/"
echo "   Version: $TIMESTAMP"
echo ""
echo "📦 Upload $BUILD/ to your server."
echo ""
echo "⚠️  IMPORTANT: Make sure your server serves index.html with no-cache headers."
echo "   Add this to your Nginx config inside the server block:"
echo ""
echo "   location = /index.html {"
echo "     add_header Cache-Control 'no-store, no-cache, must-revalidate';"
echo "     expires 0;"
echo "   }"
