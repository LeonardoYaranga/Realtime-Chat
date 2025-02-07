import { Injectable, OnModuleDestroy } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { join } from 'path';

@Injectable()
export class FirebaseService implements OnModuleDestroy {
  private static instance: FirebaseService;
  private messaging: admin.messaging.Messaging;
  private firestore: admin.firestore.Firestore;

  constructor() {
    if (!FirebaseService.instance) {
      admin.initializeApp({
        credential: admin.credential.cert(
          join(
            __dirname,
            '../../kasaychi-community-firebase-adminsdk-fbsvc-c286c1ca4e.json',
          ),
        ),
      });

      this.messaging = admin.messaging();
      this.firestore = admin.firestore();

      FirebaseService.instance = this;
    }

    return FirebaseService.instance;
  }

  async saveUserToken(email: string, token: string) {
    await this.firestore
      .collection('users')
      .doc(email)
      .set({ token }, { merge: true });
  }

  // async sendNotification(token: string, title: string, body: string) {
  //   const message = {
  //     notification: { title, body },
  //     token,
  //   };

  //   return this.messaging.send(message);
  // }

  // Implementación del envío de notificaciones push
  async sendNotification(token: string, title: string, body: string) {
    const messagePayload: admin.messaging.Message = {
      notification: {
        title: title,
        body: body,
      },
      token: token,
    };

    try {
      const response = await this.messaging.send(messagePayload);
      console.log('Notificación enviada correctamente:', response);
      return response;
    } catch (error) {
      console.error('Error al enviar notificación:', error);
      throw error;
    }
  }

  async saveMessage(remitente: string, receptor: string, texto: string) {
    const mensaje = {
      remitente,
      receptor,
      texto,
      hora: new Date().toISOString(),
    };

    await this.firestore.collection('mensajes').add(mensaje);
    return mensaje;
  }
  
  async getUsers() {
    const snapshot = await this.firestore.collection('users').get();
    return snapshot.docs.map((doc) => ({
      email: doc.id,
      token: doc.data().token,
    }));
  }

  // Cleanup en caso de que NestJS se reinicie
  onModuleDestroy() {
    admin.app().delete();
  }
}
