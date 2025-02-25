import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_restaurant_page.dart';

class MyRestaurantsPage extends StatelessWidget {
  final String userId;

  const MyRestaurantsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Restaurantes'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: _buildRestaurantList(),
    );
  }

  Widget _buildRestaurantList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .where('ownerId', isEqualTo: userId) // Filtrando pelos restaurantes do usuário
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Você ainda não cadastrou nenhum restaurante."),
          );
        }

        var restaurants = snapshot.data!.docs;

        return ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            var restaurant = restaurants[index];
            var restaurantData = restaurant.data() as Map<String, dynamic>;

            return _buildRestaurantItem(restaurant.id, restaurantData, context);
          },
        );
      },
    );
  }

  Widget _buildRestaurantItem(
      String restaurantId, Map<String, dynamic> restaurantData, BuildContext context) {
    return Dismissible(
      key: Key(restaurantId), // Chave única para cada item
      direction: DismissDirection.horizontal, // Permite arrastar para ambos os lados
      background: Container(
        color: Colors.blue, // Cor de fundo ao arrastar para a esquerda (editar)
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red, // Cor de fundo ao arrastar para a direita (excluir)
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Exibir confirmação antes de excluir
          return await _showDeleteConfirmationDialog(context);
        }
        return true; // Sem confirmação para editar
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Navegar para a tela de edição
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditRestaurantPage(restaurantId: restaurantId),
            ),
          );
        } else if (direction == DismissDirection.endToStart) {
          // Excluir o restaurante
          await _deleteRestaurant(restaurantId, context);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 4,
        child: ListTile(
          leading: restaurantData['images'] != null &&
                  (restaurantData['images'] as List).isNotEmpty
              ? Image.network(
                  restaurantData['images'][0], // Exibe a primeira imagem
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.restaurant, size: 50),
          title: Text(
            restaurantData['name'] ?? 'Nome não disponível',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(restaurantData['cuisine'] ?? 'Tipo não informado'),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Restaurante'),
          content: const Text('Tem certeza que deseja excluir este restaurante?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancelar
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirmar
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false; // Retorna false se o diálogo for fechado sem escolha
  }

  Future<void> _deleteRestaurant(String restaurantId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurante excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir restaurante.')),
      );
    }
  }
}