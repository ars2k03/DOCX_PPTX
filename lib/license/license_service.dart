import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

enum LicenseStatus {
  notActivated,
  active,
  expired,
}

class LicenseService {
  static const String _activatedAtKey = 'license_activated_at';

  static const Duration _licenseDuration = Duration(
    days: appLicenseDurationDays,
  );

  Future<LicenseStatus> checkLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final activatedAtRaw = prefs.getString(_activatedAtKey);

    if (activatedAtRaw == null) {
      return LicenseStatus.notActivated;
    }

    final activatedAt = DateTime.tryParse(activatedAtRaw);

    if (activatedAt == null) {
      await prefs.remove(_activatedAtKey);
      return LicenseStatus.notActivated;
    }

    final expiresAt = activatedAt.add(_licenseDuration);

    if (DateTime.now().isAfter(expiresAt) ||
        DateTime.now().isAtSameMomentAs(expiresAt)) {
      return LicenseStatus.expired;
    }

    return LicenseStatus.active;
  }

  Future<bool> activate(String inputCode) async {
    final cleanedCode = inputCode.trim();

    final doc = await FirebaseFirestore.instance
        .collection('licenses')
        .doc(cleanedCode)
        .get();

    if (!doc.exists) {
      return false;
    }

    final data = doc.data()!;

    if (data['used'] == true) {
      return false;
    }

    await FirebaseFirestore.instance
        .collection('licenses')
        .doc(cleanedCode)
        .update({
      'used': true,
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _activatedAtKey,
      DateTime.now().toIso8601String(),
    );

    return true;
  }

  Future<Duration?> remainingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final activatedAtRaw = prefs.getString(_activatedAtKey);

    if (activatedAtRaw == null) {
      return null;
    }

    final activatedAt = DateTime.tryParse(activatedAtRaw);

    if (activatedAt == null) {
      return null;
    }

    final expiresAt = activatedAt.add(_licenseDuration);
    final remaining = expiresAt.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      return Duration.zero;
    }

    return remaining;
  }
}