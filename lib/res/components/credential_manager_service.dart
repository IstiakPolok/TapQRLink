import 'package:flutter/services.dart';

class CredentialManagerService {
  static const MethodChannel _channel = MethodChannel(
    'com.tapqrlink/credentials',
  );

  static Future<void> saveCredentials({
    required String username,
    required String password,
    String? domain,
  }) async {
    try {
      await _channel.invokeMethod('saveCredentials', {
        'username': username,
        'password': password,
        'domain': domain,
      });
    } on PlatformException {
      // Ignore platform errors; Autofill still handles save prompts.
    }
  }
}

