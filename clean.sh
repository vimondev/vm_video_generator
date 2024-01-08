rm -rf pubspec.lock ios/Podfile.lock
flutter clean
flutter pub get
cd ios
arch -x86_64 pod install