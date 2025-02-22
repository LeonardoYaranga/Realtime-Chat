// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut(); // 🔹 Usa _auth en lugar de FirebaseAuth.instance
      print("Iniciando autenticación con Google...");

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print("Inicio de sesión cancelado por el usuario.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Obteniendo credenciales de Firebase...");
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print("Inicio de sesión exitoso, usuario: ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      print("Error en la autenticación con Google: $e");
      return null;
    }
  }

  Future<void> sendTokenToBackend(String email, String token) async {
    final response = await http.post(
      Uri.parse(
          "http://192.168.100.231:3000/auth/register"), // si e sun  dispositivo fisico, cambiar la ip por la de la maquina
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "token": token}),
    );

    if (response.statusCode == 200) {
      print("Usuario registrado en el backend");
    } else {
      print("Error al registrar usuario: ${response.body}");
    }
  }

  Future<void> guardarTokenEnBackend(String token) async {
  // Envía el token al backend
  final response = await http.post(
    Uri.parse("http://192.168.100.231:3000/auth/update-token"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": FirebaseAuth.instance.currentUser!.email, "token": token}),
  );

  if (response.statusCode == 200) {
    print("Token guardado en el backend correctamente");
  } else {
    print("Error al guardar el token en el backend: ${response.body}");
  }
}

}
