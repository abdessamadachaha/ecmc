import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:homepage/providers/cart_provider.dart';

class Cartdetails extends StatefulWidget {
  const Cartdetails({super.key});

  @override
  State<Cartdetails> createState() => _CartdetailsState();
}

class _CartdetailsState extends State<Cartdetails> {
  @override
  Widget build(BuildContext context) {
    final provider = CartProvider.of(context);
    final finalList = provider.cart;

    _buildProductQuantity(IconData icon, int index) {
      return GestureDetector(
        onTap: () {
          setState(() {
            icon == LucideIcons.circle_plus
                ? provider.incrementQuantity(index)
                : provider.decrementQuantity(index);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xfffce12)
          ),
          child: Icon(icon, size: 20, color: Colors.deepOrange,),
          
        ),
        
        
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Cart', style: TextStyle(fontSize: 25.0)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 15),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: finalList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            borderRadius: BorderRadius.circular(5.0),
                            onPressed: (context) {
                              finalList.removeAt(index);
                              setState(() {
                                
                              });
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: LucideIcons.trash_2,
                            label: 'Delete',
                          ),
                        ],
                      ),

                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0)
                        ),
                        leading: Image.network(finalList[index].product.image, height: 70,),
                        tileColor: Colors.white70,
                        title: Padding(
                          padding: EdgeInsets.only(bottom: 3.0),
                          child: Text(
                            finalList[index].product.nameOfProduct,
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            _buildProductQuantity(LucideIcons.circle_minus, index),
                            Padding(
                              padding: EdgeInsets.only(left: 4, right: 4),
                              child: Text(
                                finalList[index].quantity.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            _buildProductQuantity(LucideIcons.circle_plus, index)
                          ],
                        ),
                        trailing: Text(
                          '${finalList[index].product.price} MAD',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
