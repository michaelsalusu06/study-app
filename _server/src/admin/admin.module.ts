import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { EncryptionService } from 'src/common/encryption/encryption.service';

@Module({
  controllers: [AdminController],
  providers: [AdminService, EncryptionService],
})
export class AdminModule {}
