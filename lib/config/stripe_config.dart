import 'package:flutter_stripe/flutter_stripe.dart';

class StripeConfig {
  static void init() {
    Stripe.publishableKey = 'pk_test_51RcVFYQPHHxt540Z3qQxq1dol2g8q4I3UtCYQDiuDGw0gNq6FTAYByqrJAPQZP6qiEAjIpnuNokQvLP1J6xVLDZe00OUMjfNwF'; // Remplace par ta clé publique
  }
}