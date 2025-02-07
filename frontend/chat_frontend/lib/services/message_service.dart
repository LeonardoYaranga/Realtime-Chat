import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendMessage(String remitente, String receptor, String texto, String token) async {
  final response = await http.post(
    Uri.parse("http://10.0.2.2:3000/message/send"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "remitente": remitente,
      "receptor": receptor,
      "texto": texto,
      "token": token
    }),
  );

  if (response.statusCode == 200) {
    print("Mensaje enviado correctamente");
  } else {
    print("Error al enviar mensaje: ${response.body}");
  }
}
