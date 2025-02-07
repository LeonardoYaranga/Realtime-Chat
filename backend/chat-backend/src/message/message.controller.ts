import { Controller, Post, Body } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';

@Controller('message')
export class MessageController {
  constructor(private readonly firebaseService: FirebaseService) {}

  // 📩 Endpoint para enviar un mensaje y notificar al usuario receptor
  @Post('send')
  async sendMessage(
    @Body('remitente') remitente: string,
    @Body('receptor') receptor: string,
    @Body('texto') texto: string,
    @Body('token') token: string,  // Token FCM del receptor
  ) {
    // Guardar mensaje en Firestore
    const message = await this.firebaseService.saveMessage(remitente, receptor, texto);

    if (token) {
      await this.firebaseService.sendNotification(token,remitente, texto);
    } else {
      console.warn("⚠️ No se encontró token FCM para el receptor");
    }
    return { success: true, message };
  }
}
