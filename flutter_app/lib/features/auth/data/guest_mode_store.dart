import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class GuestModeStore {
  static const String _guestModeKey = 'com.sundeefundee.guestModeEnabled';
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> watchGuestModeChanges() => _controller.stream;

  Future<bool> isGuestModeEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> setGuestModeEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, enabled);
    _controller.add(enabled);
  }
}
