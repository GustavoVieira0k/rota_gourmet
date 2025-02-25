import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rota_gourmet/models/users.dart';
import 'package:rota_gourmet/services/users_services.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UsersServices _usersServices = UsersServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _imageFile;
  String? _profileImageUrl;
  Users? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carrega os dados do usuário ao abrir a página
  Future<void> _loadUserData() async {
    Users? user = await _usersServices.getUserData();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.userName ?? "";
        _profileImageUrl = user
            .email; // Se o Firestore tiver a URL da foto, use-a; caso contrário, remova esta linha.
      });
    }
  }

  // Seleciona imagem da galeria
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Salva as alterações do perfil (nome, senha e foto) no Firebase
  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    User? user = _auth.currentUser;
    String userId = user!.uid;

    try {
      // Atualiza o nome no Firestore
      await _firestore.collection('users').doc(userId).update({
        'userName': _nameController.text,
      });

      // Atualiza a senha se o usuário informou uma nova
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      }

      // Se uma nova foto foi selecionada, envia para o Firebase Storage e atualiza o Firestore
      if (_imageFile != null) {
        String filePath = 'profile_images/$userId.jpg';
        UploadTask uploadTask = _storage.ref(filePath).putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('users').doc(userId).update({
          'profileImage': downloadUrl,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Foto do Perfil
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!) as ImageProvider
                    : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage('assets/images/default_avatar.png')),
                child: _imageFile == null && _profileImageUrl == null
                    ? const Icon(Icons.camera_alt,
                        size: 30, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Campo Nome
            _buildTextField("Nome", _nameController),
            const SizedBox(height: 10),

            // Exibe o e-mail como informação, sem permitir alteração
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    _currentUser?.email ?? "Email não disponível",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Campo Nova Senha
            _buildTextField("Nova Senha", _passwordController,
                obscureText: true),
            const SizedBox(height: 20),

            // Botão Salvar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveProfile,
              child: const Text("Salvar Alterações",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Editar Perfil",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      centerTitle: true,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.green),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
