import 'package:cloud_firestore/cloud_firestore.dart'; 

class Users {
  String? id;
  String? userName;
  String? email;

  Users({this.id, this.userName, this.email});

  // Converte para JSON para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Se necessário
      'userName': userName,
      'email': email,
    };
  }

  // Converte de JSON para objeto Users (usado ao recuperar do Firestore)
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
    );
  }
} 