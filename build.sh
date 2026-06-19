#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter Version..."
flutter --version

echo "Setting up environment..."
if [ -f .env.example ]; then
  cp .env.example .env
else
  touch .env
fi

# Inject Vercel System Variables into the Flutter Asset
if [ ! -z "$API_BASE_URL" ]; then
  echo "" >> .env
  echo "API_BASE_URL=$API_BASE_URL" >> .env
  echo "Injected API_BASE_URL from Vercel Environment!"
fi

echo "Building Flutter Web App..."
flutter config --enable-web
flutter pub get
flutter build web --release
