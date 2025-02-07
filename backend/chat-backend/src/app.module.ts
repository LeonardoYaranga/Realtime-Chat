import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { ConfigModule } from '@nestjs/config';
import { AppService } from './app.service';
import { FirebaseService } from './firebase/firebase.service';
import { FirebaseModule } from './firebase/firebase.module';
import { MessageController } from './message/message.controller';
import { AuthController } from './auth/auth.controller';

@Module({
  imports: [FirebaseModule],
  controllers: [AppController, MessageController, AuthController],
  providers: [AppService,FirebaseService],
})
export class AppModule {}
