import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:homepage/providers/favorite_provider.dart';

class FacoriteScreen extends StatefulWidget {
  const FacoriteScreen({super.key});

  @override
  State<FacoriteScreen> createState() => _FacoriteScreenState();
}

class _FacoriteScreenState extends State<FacoriteScreen> {
      

  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context);
    final finalList = provider.favorites;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Wishlist', style: TextStyle(fontSize: 25.0),),
        centerTitle: true,       
      ),
      body: Column(
      children: [
        Expanded(
          
          child: ListView.builder(
            itemCount: finalList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(8.0),
                child: Card(
                  child: ListTile(
                    title: Text(
                      finalList[index].nameOfProduct,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      finalList[index].description,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                    leading: CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(finalList[index].image),
                    ),
                  
                    trailing: Text(
                      '${finalList[index].price} MAD',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold
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

    );
    
  }
}
