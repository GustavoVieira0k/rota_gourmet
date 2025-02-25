import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rota_gourmet/models/users.dart';

class UsersServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Users users = Users();

  DocumentReference get _docRef => _firestore.doc('users/${users.id}');

  Future<Users?> getUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          return Users.fromJson(userDoc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do usuário: $e");
    }
    return null;
  }

  // Método para registrar o usuário no Firebase Authentication e salvar detalhes no Firestore
  Future<bool> signUp(String email, String password, String userName) async {
    try {
      User? user = (await _auth.createUserWithEmailAndPassword(
              email: email, password: password))
          .user;

      users.id = user!.uid;
      users.email = email;
      users.userName = userName;
      saveUserDetails();
      return Future.value(true);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-email') {
        debugPrint("O email informado está com formato inválido");
      } else if (error.code == 'email-already-in-use') {
        debugPrint("O email informado já está em uso");
      } else if (error.code == 'weak-password') {
        debugPrint("A senha informada é muito fraca");
      }
      return Future.value(false);
    } catch (e) {
      debugPrint("Erro inesperado: $e");
      return Future.value(false);
    }
  }

  Future<bool> signIn(
      {String? email,
      String? password,
      Function? onSucess,
      Function? onFail}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email!,
        password: password!,
      );
      onSucess!();
      return Future.value(true);
    } on FirebaseAuthException catch (e) {
      String code = '';
      if (e.code == 'user-not-found') {
        code = 'Não há usuário registrado com este email';
      } else if (e.code == 'wrong-password') {
        code = 'A senha informada não confere';
      } else if (e.code == 'invalid-email') {
        code = 'O email informado está com formato inválido';
      } else if (e.code == 'user-disabled') {
        code = 'Email do usuário está desabilitado';
      }
      onFail!(code);
      return Future.value(false);
    }
  }

  // Método para salvar os detalhes do usuário no Firestore
  saveUserDetails() async {
    if (users != null) {
      await _docRef.set(users.toJson());
    } else {
      debugPrint('Usuário não encontrado');
    }
  }
}
