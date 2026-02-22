void main() {
  const bool firebaseEnabled = bool.fromEnvironment('ENABLE_FIREBASE', defaultValue: false);
  print('Firebase enabled: $firebaseEnabled');
}
