import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:homepage/Widgets/Button.dart';
import 'package:homepage/models/product.dart';
import 'package:homepage/models/person.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Detailsscreen extends StatefulWidget {
  final Product product;
  Detailsscreen({super.key, required this.product});

  @override
  State<Detailsscreen> createState() => _DetailsscreenState();
}

class _DetailsscreenState extends State<Detailsscreen> {
  Person? seller;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSellerInfo();
  }

  void fetchSellerInfo() async {
    try {
      final response =
          await Supabase.instance.client
              .from('users')
              .select('*')
              .eq('id', widget.product.idSeller)
              .single();

      setState(() {
        seller = Person.fromMap(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            LucideIcons.chevron_left
          ),
        ),
        actions: [
          IconButton(
            onPressed: ()=>provider.toggleProduct(widget.product),
            icon: Icon(
              provider.isExist(widget.product)?Icons.favorite : Icons.favorite_border_outlined, color: Colors.red,
          ),
          ),
        ],

        title: Text(
          widget.product.nameOfProduct,
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          
            Image.network(
              widget.product.image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '${widget.product.price.toString()} MAD',
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          widget.product.condition,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.0),
                    child: Text(
                      widget.product.description.isNotEmpty ? widget.product.description : '',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(18.0),
                    child:
                        isLoading
                            ? CircularProgressIndicator()
                            : Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage:
                                      seller?.image != null
                                          ? NetworkImage(seller!.image!)
                                          : null,
                                  child:
                                      seller?.image == null
                                          ? Icon(LucideIcons.user_round)
                                          : null,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  seller?.name ?? 'Inkonnu',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                  ),

                  Button(text: 'Add To Cart'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
