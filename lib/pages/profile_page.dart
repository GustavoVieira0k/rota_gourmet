import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rota_gourmet/pages/add_restaurant_page.dart';
import 'package:rota_gourmet/pages/edit_profile_page.dart';
import 'package:rota_gourmet/pages/favorites_page.dart';
import 'package:rota_gourmet/pages/home_page.dart';
import 'package:rota_gourmet/pages/my_restaurants_page.dart'; // Importação adicionada

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildProfileContent(context),
      bottomNavigationBar: _buildBottomNavigationBar(context, 3),
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
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text("Usuário não autenticado."),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Erro ao carregar dados do perfil."));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const Center(child: Text("Dados do usuário não encontrados."));
        }

        String name = userData['userName'] ?? "Nome não definido";
        String email = userData['email'] ?? "Email não disponível";
        String photoUrl =
            userData['photoURL'] ?? 'assets/images/default_avatar.png';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto do perfil
              CircleAvatar(
                radius: 60,
                backgroundImage: photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl)
                    : AssetImage(photoUrl) as ImageProvider,
              ),
              const SizedBox(height: 10),

              // Nome do usuário
              Text(
                name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              // Email do usuário
              Text(
                email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Botões
              _buildProfileButton(Icons.edit, "Editar Perfil", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              }),
              _buildProfileButton(Icons.restaurant, "Meus Restaurantes", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MyRestaurantsPage(
                          userId: user.uid)), // Chama a nova página
                );
              }),
              _buildProfileButton(Icons.rate_review, "Minhas Avaliações", () {
                // Navegar para a tela de avaliações feitas
              }),
              _buildProfileButton(Icons.delete, "Excluir Conta", () {
                // Confirmar e excluir a conta do usuário
              }, isDestructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileButton(IconData icon, String text, VoidCallback onPressed,
      {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, int currentIndex) {
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
        if (index == 0) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        } else if (index == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()));
        } else if (index == 2) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddRestaurantPage()));
        }
      },
    );
  }
}
