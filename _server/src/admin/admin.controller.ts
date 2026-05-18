import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Roles } from 'src/common/decorators/roles.decorator';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { AdminService } from './admin.service';
import { VerifyTutorDto } from './dto/verify-tutor.dto';
import { ProcessRefundDto } from './dto/process-refund.dto';
import { ProcessWithdrawalDto } from './dto/process-withdrawal.dto';
import { CreateAdminDto } from './dto/create-admin.dto';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // Public during bootstrap (no admins exist), requires ADMIN JWT afterwards
  @Post('create')
  createAdmin(@Request() req: any, @Body() dto: CreateAdminDto) {
    const callerRole = req.user?.role;
    return this.adminService.createAdmin(callerRole, dto);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('stats')
  getStats() {
    return this.adminService.getStats();
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('users')
  getAllUsers(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getAllUsers(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('users/:id')
  getUserById(@Param('id') id: string) {
    return this.adminService.getUserById(id);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('tutors/pending')
  getPendingTutors() {
    return this.adminService.getPendingTutors();
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('tutors/:id')
  getTutorDetail(@Param('id') id: string) {
    return this.adminService.getTutorDetail(id);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Patch('tutors/:id/verify')
  verifyTutor(
    @Param('id') id: string,
    @Request() req: any,
    @Body() dto: VerifyTutorDto,
  ) {
    const adminId = req.user.userId || req.user.sub;
    return this.adminService.verifyTutor(id, adminId, dto);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('bookings')
  getBookings(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getBookings(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('payments')
  getPaymentOrders(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.getPaymentOrders(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      status,
    );
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Post('refunds')
  processRefund(@Request() req: any, @Body() dto: ProcessRefundDto) {
    const adminId = req.user.userId || req.user.sub;
    return this.adminService.processRefund(adminId, dto);
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Get('withdrawals')
  getWithdrawals(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('status') status?: string,
  ) {
    return this.adminService.getWithdrawalRequests(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      status,
    );
  }

  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles('ADMIN')
  @Patch('withdrawals/:id')
  processWithdrawal(
    @Param('id') id: string,
    @Request() req: any,
    @Body() dto: ProcessWithdrawalDto,
  ) {
    const adminId = req.user.userId || req.user.sub;
    return this.adminService.processWithdrawal(adminId, id, dto);
  }
}
