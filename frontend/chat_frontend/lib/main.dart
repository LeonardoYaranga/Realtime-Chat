// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chat_frontend/firebase_options.dart';
import './services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Configurar notificaciones push
  await setupFirebaseMessaging();

  runApp(MyApp());
}

// ✅ Maneja mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(
    fcm.RemoteMessage message) async {
  print("📩 Mensaje recibido en segundo plano: ${message.messageId}");
}

// ✅ Configura Firebase Messaging
Future<void> setupFirebaseMessaging() async {
  fcm.FirebaseMessaging messaging = fcm.FirebaseMessaging.instance;

  fcm.NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == fcm.AuthorizationStatus.denied) {
    print("❌ El usuario denegó las notificaciones.");
    return;
  }

  // ✅ Obtener token del dispositivo
  String? token = await messaging.getToken();
  print("🔑 Token FCM del usuario: $token");

  // ✅ Registrar el manejador de mensajes en segundo plano
  fcm.FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("🔄 Estado de la autenticación: ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          print("✅ Usuario autenticado: ${snapshot.data?.email}");
          return ChatScreen(); // Redirige a la pantalla de chat si ya está autenticado
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  final AuthService authService = AuthService();

  LoginScreen({super.key});

  Future<String?> getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("📲 Token del dispositivo: $token");
    if (token != null) {
      // Aquí puedes enviar el token al backend y guardarlo en la base de datos
      await authService.guardarTokenEnBackend(token);
    }

    return token;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar sesión")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            print("🚀 Iniciando sesión con Google...");
            User? user = await authService.signInWithGoogle();
            if (user != null) {
              print("✅ Usuario autenticado: ${user.email}");
              String? token = await getDeviceToken();
              if (token != null) {
                print("📡 Enviando token al backend...");
                await authService.sendTokenToBackend(user.email!, token);
              }

              print("➡️ Navegando a ChatScreen...");
              Future.delayed(Duration(milliseconds: 500), () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              });
            }
          },
          child: Text("Iniciar sesión con Google"),
        ),
      ),
    );
  }
}
