import { Test, TestingModule } from '@nestjs/testing';
import { MessageController } from './message.controller';
import { FirebaseService } from '../firebase/firebase.service';

describe('MessageController', () => {
  let messageController: MessageController;
  let firebaseService: FirebaseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MessageController],
      providers: [
        {
          provide: FirebaseService,
          useValue: {
            saveMessage: jest.fn().mockResolvedValue({
              id: '1',
              remitente: 'user1',
              receptor: 'user2',
              texto: 'Hola!',
            }),
            sendNotification: jest.fn(),
          },
        },
      ],
    }).compile();

    messageController = module.get<MessageController>(MessageController);
    firebaseService = module.get<FirebaseService>(FirebaseService);
  });

  // Caso de prueba 3: Envío de mensaje con notificación
  it('debería enviar un mensaje y notificar al receptor', async () => {
    const mockMessage = {
      remitente: 'user1',
      receptor: 'user2',
      texto: 'Hola!',
      token: 'abcd1234',
    };

    const result = await messageController.sendMessage(
      mockMessage.remitente,
      mockMessage.receptor,
      mockMessage.texto,
      mockMessage.token,
    );

    expect(result).toEqual({
      success: true,
      message: {
        id: '1',
        remitente: 'user1',
        receptor: 'user2',
        texto: 'Hola!',
      },
    });

    expect(firebaseService.saveMessage).toHaveBeenCalledWith(
      mockMessage.remitente,
      mockMessage.receptor,
      mockMessage.texto,
    );

    expect(firebaseService.sendNotification).toHaveBeenCalledWith(
      mockMessage.remitente,
      mockMessage.receptor,
      mockMessage.texto,
    );
  });
});
