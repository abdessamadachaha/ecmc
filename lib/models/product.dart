class Product {
  final String id;
  final String nameOfProduct;
  final String image;
  final int price;
  final String description;
  final String condition;
  final int quantity;
  final String idSeller;

  Product({
    required this.id,
    required this.nameOfProduct,
    required this.image,
    required this.price,
    required this.description,
    required this.condition,
    required this.quantity,
    required this.idSeller,
  });

    @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
