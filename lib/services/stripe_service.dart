import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:homepage/consts.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  Future<bool> makePayment({required double amount}) async {
  try {
    String? paymentIntentClientSecret = await _createPaymentIntent(
      amount.toInt(),
      'MAD',
    );
    if (paymentIntentClientSecret == null) return false;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntentClientSecret,
        merchantDisplayName: "Abdessamad Achaha",
      ),
    );

    await _processPayment();
    return true;
  } catch (e) {
    print('❌ Payment Error: $e');
    return false; // ✅ أضف هذه
  }
}


  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
      };
      var responce = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer ${stripeSecretKey}",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (responce.data != null) {
        print(responce.data);
        return responce.data["client_secret"];
      }
      return null;
    } catch (e) {
      print(e);
    }
    return null;
  }

  String _calculateAmount(int amount) {
    final calculamount = amount * 100;
    return calculamount.toString();
  }

  Future<void> _processPayment() async {
  try {
    await Stripe.instance.presentPaymentSheet();
    print("✅ Payment successful");
  } catch (e) {
    print("❌ Error during payment sheet: $e");
    rethrow; // 🔁 مهم لإعادة إرسال الخطأ إلى `makePayment`
  }
}

}
