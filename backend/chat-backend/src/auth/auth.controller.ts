import { Controller, Post, Body, Get, BadRequestException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly firebaseService: FirebaseService) {}

  @Post('register')
  async registerUser(@Body() body) {
    const { email, token } = body;
    if (!email || !token) {
      throw new Error('Faltan datos');
    }

    // Guardar en Firebase Firestore
    await this.firebaseService.saveUserToken(email, token);
    return { message: 'Usuario registrado con éxito' };
  }
  @Post('update-token')
async updateToken(@Body() body) {
  const { email, token } = body;
  if (!email || !token) {
    throw new BadRequestException('Email y token son requeridos');
  }
  await this.firebaseService.updateUserToken(email, token);
  return { message: 'Token actualizado' };
}

  
  @Get('users')
  async getUsers() {
    return await this.firebaseService.getUsers();
  }
}
