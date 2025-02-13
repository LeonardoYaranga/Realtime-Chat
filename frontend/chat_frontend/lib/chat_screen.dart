// ignore_for_file: avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/streams.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print(
            "📩 Notificación recibida en primer plano: ${message.notification!.title}");

        Fluttertoast.showToast(
          msg: "${message.notification!.title}: ${message.notification!.body}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP, // Aparece en la parte superior
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }

  void _listenMessages() {
    _firestore.collection("messages").snapshots().listen((snapshot) {
      setState(() {
        messages = snapshot.docs.map((doc) {
          var data = doc.data();
          return {
            "texto": data["texto"],
            "remitente": data["remitente"],
            "receptor": data["receptor"],
            "hora": (data["hora"] as Timestamp).toDate().toString()
          };
        }).toList();
      });
      print("📩 Mensajes actualizados en la UI: $messages");
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
      print("No hay usuario seleccionado para chatear");
      return;
    }

    final response = await http.post(
      Uri.parse("http://localhost:3000/message/send"),
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

  Stream<List<QuerySnapshot>> getChatMessagesStream() {
    if (selectedUserEmail == null) {
      print("No hay usuario seleccionado para ver mensajes");
      return Stream.value([]);
    }

    var sentMessages = _firestore
        .collection("messages")
        .where("remitente", isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .where("receptor",
            isEqualTo: selectedUserEmail) // Filtrar por receptor seleccionado
        .snapshots();

    var receivedMessages = _firestore
        .collection("messages")
        .where("remitente",
            isEqualTo: selectedUserEmail) // Filtrar por remitente seleccionado
        .where("receptor", isEqualTo: FirebaseAuth.instance.currentUser?.email)
        .snapshots();

    return CombineLatestStream.list([sentMessages, receivedMessages]);
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
            stream: getChatMessagesStream(),
            builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var messages =
                  snapshot.data!.expand((snapshot) => snapshot.docs).toList();
              messages.sort((a, b) =>
                  b["hora"].compareTo(a["hora"])); // Ordenar por fecha

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isMe = message['remitente'] ==
                      FirebaseAuth.instance.currentUser?.email;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['texto'],
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "De: ${message['remitente']}",
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )),

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
