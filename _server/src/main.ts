import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const express = require('express');
import { AppModule } from './app.module';

const expressApp = express();
let isReady = false;

async function bootstrap() {
  if (isReady) return expressApp;

  const app = await NestFactory.create(AppModule, new ExpressAdapter(expressApp));

  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  await app.init();
  isReady = true;
  return expressApp;
}

// Vercel serverless handler
export default async (req: any, res: any) => {
  await bootstrap();
  expressApp(req, res);
};

// Local dev — only runs when executed directly (npm run start:dev / start:prod)
if (require.main === module) {
  bootstrap().then((server) => {
    server.listen(process.env.PORT ?? 3000, () => {
      console.log(`Server running on port ${process.env.PORT ?? 3000}`);
    });
  });
}
