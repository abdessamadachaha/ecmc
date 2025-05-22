import 'package:flutter/material.dart';
import 'package:homepage/models/CartItem.dart';
import 'package:homepage/models/product.dart';
import 'package:provider/provider.dart';

class CartProvider extends ChangeNotifier {
  final List<Cartitem> _cart = [];
  List<Cartitem> get cart => _cart;

  void toggleProduct(Cartitem cartitem) {
    if (_cart.contains(cartitem.product)) {
      for (Cartitem element in _cart) {
        element.quantity++;
      }
    } else {
      _cart.add(cartitem);
    }
    notifyListeners();
  }

  void incrementQuantity(int index) {
  if (_cart[index].quantity < _cart[index].product.quantity) {
    _cart[index].quantity++;
    notifyListeners();
  }
}


  decrementQuantity(int index) {
    if (_cart[index].quantity > 1) {
    _cart[index].quantity--;
    } 
  }

 

  static CartProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<CartProvider>(context, listen: listen);
  }
}
