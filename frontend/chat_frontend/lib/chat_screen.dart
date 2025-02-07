// ignore_for_file: avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  List<Map<String, String>> users = [];
  String? selectedUserEmail;
  String? selectedUserToken;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _listenMessages();
    loadUsers();

    // 📩 Manejar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print(
            "📩 Notificación recibida en primer plano: ${message.notification!.title}");

        // Mostrar SnackBar con la notificación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${message.notification!.title}: ${message.notification!.body}"),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                print("🔍 Ir al chat...");
              },
            ),
          ),
        );
      }
    });

    // 📬 Manejar notificaciones tocadas cuando la app estaba en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 Notificación tocada: ${message.notification?.title}");
    });
    
  }

  void _listenMessages() {
    _firestore.collection("messages").snapshots().listen((snapshot) {
      setState(() {
        messages = snapshot.docs.map((doc) => doc.data()).toList();
      });
    });
  }

  Future<List<Map<String, String>>> getUsers() async {
    final response =
        await http.get(Uri.parse("http://192.168.100.231:3000/auth/users"));
    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body);
      return users
          .map((user) => {
                "email": user["email"] as String,
                "token": user["token"] as String,
              })
          .toList();
    } else {
      print("Error al obtener usuarios: ${response.body}");
      return [];
    }
  }

  Future<void> loadUsers() async {
    List<Map<String, String>> fetchedUsers = await getUsers();
    setState(() {
      users = fetchedUsers;
      if (users.isNotEmpty) {
        selectedUserEmail = users.first["email"];
        selectedUserToken = users.first["token"];
      }
    });
  }

  Future<void> sendMessage(String message) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        selectedUserEmail == null ||
        selectedUserToken == null) {
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.100.231:3000/message/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "remitente": user.email,
        "receptor": selectedUserEmail,
        "texto": message,
        "token": selectedUserToken,
      }),
    );

    if (response.statusCode == 200) {
      print("Mensaje enviado correctamente");
    } else {
      print("Error al enviar mensaje: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(
                  context, "/login"); // Redirige al login
            },
          ),
        ],
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedUserEmail,
            hint: Text("Selecciona un usuario"),
            onChanged: (String? newValue) {
              setState(() {
                selectedUserEmail = newValue;
                selectedUserToken = users
                    .firstWhere((user) => user["email"] == newValue)["token"];
              });
            },
            items: users.map<DropdownMenuItem<String>>((user) {
              return DropdownMenuItem<String>(
                value: user["email"],
                child: Text(user["email"]!),
              );
            }).toList(),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection("messages").snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    return ListTile(
                      title: Text(message['texto']),
                      subtitle: Text("De: ${message['remitente']}"),
                    );
                  },
                );
              },
            ),
          ),
          // Aquí van los mensajes
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration:
                        InputDecoration(hintText: "Escribe un mensaje..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      sendMessage(messageController.text);
                      messageController.clear();
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
