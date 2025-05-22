import 'package:homepage/models/product.dart';

class Cartitem {
  Product product;
  int quantity = 0;

  Cartitem({required this.product, required this.quantity});
}
