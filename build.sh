#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter Version..."
flutter --version

echo "Building Flutter Web App..."
flutter config --enable-web
flutter pub get

# Pass API_BASE_URL as a Dart compile-time constant so it is baked into the JS bundle
if [ ! -z "$API_BASE_URL" ]; then
  echo "Building with API_BASE_URL=$API_BASE_URL"
  flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
else
  echo "Building with default API_BASE_URL"
  flutter build web --release
fi
