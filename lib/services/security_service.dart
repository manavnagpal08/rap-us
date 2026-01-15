import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:otp/otp.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticateBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to proceed with this sensitive action',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric Error: $e');
      return false;
    }
  }

  String generateTotpSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // Base32 alphabet
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String getTotpUri(String secret, String accountName) {
    return 'otpauth://totp/RAP:$accountName?secret=$secret&issuer=RAP%20US';
  }

  bool verifyTotp(String secret, String otp) {
    try {
      final String code = OTP.generateTOTPCodeString(
        secret, 
        DateTime.now().millisecondsSinceEpoch, 
        algorithm: Algorithm.SHA1,
        interval: 30,
      );
      return code == otp;
    } catch (e) {
      debugPrint('TOTP Error: $e');
      return false;
    }
  }
}
