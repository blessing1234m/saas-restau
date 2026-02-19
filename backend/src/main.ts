import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as express from 'express';

async function bootstrap() {

  const app = await NestFactory.create(AppModule);
  
  // Augmenter la limite de taille du body pour les images
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ limit: '10mb', extended: true }));
  
  // Activer CORS
  app.enableCors({
    origin: '*',
    credentials: true,
  });
  
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: false,
    transformOptions: {
      enableImplicitConversion: true,
    },
    exceptionFactory: (errors) => {
      const messages = errors.map(error => ({
        field: error.property,
        constraints: error.constraints,
      }));
      const errorMessage = errors
        .map(e => `${e.property}: ${Object.values(e.constraints || {}).join(', ')}`)
        .join('; ');
      const error = new Error(errorMessage);
      (error as any).statusCode = 400;
      (error as any).errors = messages;
      return error;
    },
  }));

  // Configuration Swagger
  const config = new DocumentBuilder()
    .setTitle('Restaurant SaaS API')
    .setDescription('Documentation de l\'API Restaurant SaaS')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(3000, '0.0.0.0');
}
  bootstrap();
