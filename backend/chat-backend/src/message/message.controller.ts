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
    @Body('token') token: string,
  ) {
    console.log(
      `Mensaje recibido en backend: ${remitente} -> ${receptor}: ${texto}`,
    );

    const message = await this.firebaseService.saveMessage(
      remitente,
      receptor,
      texto,
    );
    console.log(`📩 Mensaje guardado en Firestore:`, message);

    if (token) {
      console.log(`Enviando notificación a ${receptor} con token ${token}`);
      await this.firebaseService.sendNotification(remitente, receptor, texto);
    } else {
      console.warn('⚠️ No se encontró token FCM para el receptor');
    }

    return { success: true, message };
  }
}
