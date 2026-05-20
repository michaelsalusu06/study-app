import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { EncryptionService } from 'src/common/encryption/encryption.service';
import { DailyModule } from 'src/daily/daily.module';

@Module({
  imports: [DailyModule],
  controllers: [AdminController],
  providers: [AdminService, EncryptionService],
})
export class AdminModule {}
