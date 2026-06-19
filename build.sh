#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter Version..."
flutter --version

echo "Building Flutter Web App..."
flutter config --enable-web
flutter pub get
flutter build web --release
