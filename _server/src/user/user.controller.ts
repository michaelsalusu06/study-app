import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UserService } from './user.service';
import { UpdateProfileDTO } from './dto/update-profile.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';
import { CreateTutorOfferDto } from './dto/create-tutor-offer.dto';
import { UpdateTutorOfferDto } from './dto/update-tutor-offer.dto';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  // ---------- Public tutor/student listing ----------

  @Get('tutors/all')
  getAllProfile() {
    return this.userService.getAllTutorProfile();
  }

  @Get('student')
  getStudentProfile() {
    return this.userService.getAllStudentProfile();
  }

  // GET /user/tutors?search=math&maxCoins=20
  @Get('tutors')
  getTutorList(
    @Query('search') search?: string,
    @Query('subject') subject?: string,
    @Query('maxCoins') maxCoins?: string,
  ) {
    return this.userService.getTutorFilteredBy(
      search,
      subject,
      maxCoins ? parseInt(maxCoins, 10) : undefined,
    );
  }

  @Get('tutor/:id')
  getTutorDetail(@Param('id') id: string) {
    return this.userService.getTutorDetailProfile(id);
  }

  // ---------- TutorOffer CRUD (JWT required) ----------

  @UseGuards(AuthGuard('jwt'))
  @Post('tutor/offer')
  createOffer(@Request() req: any, @Body() dto: CreateTutorOfferDto) {
    return this.userService.createOffer(req.user.userId || req.user.sub, dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('tutor/offer/mine')
  getMyOffers(@Request() req: any) {
    return this.userService.getMyOffers(req.user.userId || req.user.sub);
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('tutor/offer/:id')
  updateOffer(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateTutorOfferDto,
  ) {
    return this.userService.updateOffer(req.user.userId || req.user.sub, id, dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('tutor/offer/:id')
  deleteOffer(@Request() req: any, @Param('id') id: string) {
    return this.userService.deleteOffer(req.user.userId || req.user.sub, id);
  }

  // ---------- Profile ----------

  @UseGuards(AuthGuard('jwt'))
  @Post('tutor/verification')
  submitVerification(@Request() req: any, @Body() dto: SubmitVerificationDto) {
    const userId = req.user.userId || req.user.sub;
    if (!userId) throw new UnauthorizedException('Identification missing in token.');
    return this.userService.submitVerification(userId, dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('update/profile')
  updateProfile(@Request() req: any, @Body() updateData: UpdateProfileDTO) {
    const userId = req.user.userId || req.user.sub || req.user.id;
    if (!userId) throw new UnauthorizedException('Identification missing in token.');
    return this.userService.updateProfile(userId, updateData);
  }

  @Get()
  getDummyData() {
    return { message: 'UserController OK.', timestamp: new Date() };
  }
}
