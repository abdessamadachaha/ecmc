import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:homepage/Views/CartDetails.dart';
import 'package:homepage/Widgets/Button.dart';
import 'package:homepage/models/CartItem.dart';
import 'package:homepage/models/product.dart';
import 'package:homepage/models/person.dart';
import 'package:homepage/providers/cart_provider.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:provider/provider.dart';
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

  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;


  @override
  void initState() {
    super.initState();
    fetchSellerInfo();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    setState(() => _loadingReviews = true);
    final data = await Supabase.instance.client
        .from('review')
        .select('comment, created_at, users(name)')
        .eq('product_id', widget.product.id)
        .order('created_at', ascending: false);

    setState(() {
      _reviews = data;
      _loadingReviews = false;
    });
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

  Future<void> addComment() async {
    final comment = _commentController.text.trim();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (comment.isNotEmpty && userId != null) {
      await Supabase.instance.client.from('review').insert({
        'product_id': widget.product.id,
        'user_id': userId,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
      fetchReviews(); // rafraîchir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Commentaire ajouté')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context);
    final providerCart = CartProvider.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(LucideIcons.chevron_left),
        ),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, provider, _) {
              return IconButton(
                onPressed: () => provider.toggleProduct(widget.product),
                icon: Icon(
                  provider.isExist(widget.product)
                      ? Icons.favorite
                      : Icons.favorite_border_outlined,
                  color: Colors.red,
                ),
              );
            },
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
                      widget.product.description.isNotEmpty
                          ? widget.product.description
                          : '',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📝 Laisser un commentaire',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Écris ton avis ici...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: addComment,
                            icon: const Icon(Icons.send , color: Colors.white,),
                            label: const Text("Envoyer"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💬 Commentaires récents',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        _loadingReviews
                            ? const Center(child: CircularProgressIndicator())
                            : _reviews.isEmpty
                            ? const Text('Aucun commentaire pour ce produit.')
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            final user = review['users']?['name'] ?? 'Utilisateur';
                            final comment = review['comment'];
                            final date = DateTime.parse(review['created_at'])
                                .toLocal()
                                .toString()
                                .substring(0, 16);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          user,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      comment,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),



                  // Add to cart or épuisé
widget.product.quantity > 0
    ? Button(
        text: 'Add To Cart',
        onTap: () async {
          await providerCart.addToCart(
            Cartitem(product: widget.product, quantity: 1),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.nameOfProduct} ajouté au panier'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      )
    : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: ElevatedButton.icon(
          onPressed: null, // désactivé
          icon: const Icon(Icons.block, color: Colors.white),
          label: const Text("Product out of stock"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
