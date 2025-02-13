import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { FirebaseService } from '../firebase/firebase.service';
import { BadRequestException } from '@nestjs/common';

describe('AuthController', () => {
  let authController: AuthController;
  let firebaseService: FirebaseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: FirebaseService,
          useValue: {
            saveUserToken: jest.fn(),
            updateUserToken: jest.fn(),
          },
        },
      ],
    }).compile();

    authController = module.get<AuthController>(AuthController);
    firebaseService = module.get<FirebaseService>(FirebaseService);
  });

  // Caso de prueba 1: Registro de usuario exitoso
  it('debería registrar un usuario correctamente', async () => {
    const mockUser = { email: 'test@example.com', token: '123456' };

    await expect(authController.registerUser(mockUser)).resolves.toEqual({
      message: 'Usuario registrado con éxito',
    });

    expect(firebaseService.saveUserToken).toHaveBeenCalledWith(
      mockUser.email,
      mockUser.token,
    );
  });

  // Caso de prueba 2: Fallo al registrar usuario por datos faltantes
  it('debería lanzar error si faltan datos al registrar usuario', async () => {
    await expect(authController.registerUser({ email: '' })).rejects.toThrow(
      'Faltan datos',
    );
  });

  // Caso de prueba 4: Fallo al actualizar token por datos faltantes
  it('debería lanzar error si faltan datos al actualizar el token', async () => {
    await expect(authController.updateToken({ email: '' })).rejects.toThrow(
      BadRequestException,
    );
  });
});
