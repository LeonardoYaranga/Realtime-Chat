import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  List<Map<String, String>> users = [];
  String? selectedUserEmail;
  String? selectedUserToken;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<List<Map<String, String>>> getUsers() async {
    final response =
        await http.get(Uri.parse("http://10.0.2.2:3000/auth/users"));
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
    if (user == null || selectedUserEmail == null || selectedUserToken == null)
      return;

    final response = await http.post(
      Uri.parse("http://10.0.2.2:3000/message/send"),
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
          Expanded(child: Container()), // Aquí van los mensajes
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
