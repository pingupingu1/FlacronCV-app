import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  static Future<void> sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('sendEmail');

    await callable.call({
      'to': to,
      'subject': subject,
      'text': message,
    });
  }
}
