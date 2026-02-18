import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {

  const app = await NestFactory.create(AppModule);
  
  // Activer CORS
  app.enableCors({
    origin: '*',
    credentials: true,
  });
  
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe());

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
