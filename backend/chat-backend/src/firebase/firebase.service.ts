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

    async updateUserToken(email: string, token: string) {
      const userRef = admin.firestore().collection('users').doc(email);
      await userRef.set({ token }, { merge: true });
    }
  
  // Implementación del envío de notificaciones push
  async sendNotification(remitente: string, receptor: string, texto: string) {
    console.log('Enviando notificación a', receptor);
    const userRef = admin.firestore().collection('users').doc(receptor);
    const userDoc = await userRef.get();
  
    if (!userDoc.exists) {
      throw new Error('El usuario no existe');
    }
  
    const userData = userDoc.data();
    if (!userData?.token) {
      throw new Error('El usuario no tiene un token de FCM válido');
    }
  
    const message = {
      token: userData.token,
      notification: {
        title: `Nuevo mensaje de ${remitente}`,
        body: texto,
      },
    };
  
    try {
      await admin.messaging().send(message);
      console.log('Notificación enviada correctamente');
    } catch (error) {
      console.error('Error al enviar notificación:', error);
    }
  }

  async saveMessage(remitente: string, receptor: string, texto: string) {
    const messageRef = this.firestore.collection("messages").doc();
    const hora = admin.firestore.Timestamp.now();  // Guarda como Timestamp
  
    await messageRef.set({
      remitente,
      receptor,
      texto,
      hora
    });
  
    return messageRef.get();
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
