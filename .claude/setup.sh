#!/usr/bin/env bash
# Setup script for the Claude Code cloud environment.
# The VM has no Flutter SDK; this installs one and warms the caches
# so `flutter analyze` and `flutter build web` work in a session.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if ! command -v flutter >/dev/null 2>&1; then
  git clone --depth 1 -b "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bashrc"
fi

flutter config --no-analytics --enable-web
flutter precache --web

(cd packages/hlth_charts && flutter pub get)
(cd gallery && flutter pub get)
(cd widgetbook && flutter pub get && dart run build_runner build --delete-conflicting-outputs)

echo "Flutter $(flutter --version | head -n1) ready."
