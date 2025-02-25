import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favorites_page.dart';
import 'add_restaurant_page.dart';
import 'profile_page.dart';
import 'restaurant_details_page.dart';
import 'package:rota_gourmet/services/restaurant_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    RestaurantService restaurantService = RestaurantService();

    return Scaffold(
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Nenhum restaurante cadastrado ainda.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final restaurant = snapshot.data!.docs[index];
              final data = restaurant.data() as Map<String, dynamic>;
              return _buildRestaurantCard(
                  context, restaurant.id, data, restaurantService);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 0),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/images/rotagourmetlogo.png'),
      ),
      title: const Text(
        'Rota Gourmet',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.green,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Implementar a pesquisa futura
          },
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(
      BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle), label: 'Adicionar'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
      onTap: (index) {
        if (index == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()));
        } else if (index == 2) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddRestaurantPage()));
        } else if (index == 3) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        }
      },
    );
  }

  Widget _buildRestaurantCard(BuildContext context, String restaurantId,
      Map<String, dynamic> restaurant, RestaurantService restaurantService) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('reviews')
          .get(),
      builder: (context, snapshot) {
        double averageRating = 0;
        int totalReviews = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          List<double> ratings = snapshot.data!.docs
              .map((doc) => (doc['rating'] as num).toDouble())
              .toList();
          totalReviews = ratings.length;
          averageRating = ratings.reduce((a, b) => a + b) / totalReviews;
        }

        // Verifica se está aberto ou fechado
        String openingTime = restaurant['openingTime'];
        String closingTime = restaurant['closingTime'];
        List<int> daysOpen = List<int>.from(restaurant['daysOpen']);
        bool isOpen = restaurantService.isRestaurantOpen(
            openingTime, closingTime, daysOpen);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const Icon(Icons.restaurant,
                color: Colors.green, size: 50), // Ícone de restaurante
            title: Text(
              restaurant['name'] ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo: ${restaurant['cuisine'] ?? 'N/A'}'),
                Text('Preço médio: ${restaurant['price'] ?? 'N/A'}'),
                Text(
                  totalReviews > 0
                      ? 'Nota: ${averageRating.toStringAsFixed(1)} ⭐ ($totalReviews avaliações)'
                      : 'Ainda sem avaliações',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isOpen ? 'Aberto' : 'Fechado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegar para a página de detalhes do restaurante
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RestaurantDetailsPage(restaurantId: restaurantId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
