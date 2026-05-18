import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  Request,
  UseGuards,
  UnauthorizedException,
} from '@nestjs/common';
import { UserService } from './user.service';
import { UpdateProfileDTO } from './dto/update-profile.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';
import { AuthGuard } from '@nestjs/passport';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('tutors/all')
  async getAllProfile() {
    return this.userService.getAllTutorProfile();
  }

  @Get('student')
  async getStudentProfile() {
    return this.userService.getAllStudentProfile();
  }

  //  GET /user/tutors?search=math&maxPrice=150000
  @Get('tutors')
  async getTutorList(
    @Query('search') search?: string,
    @Query('subject') subject?: string,
    @Query('maxPrice') maxPrice?: string,
  ) {
    const parsedPrice = maxPrice ? parseFloat(maxPrice) : undefined;
    return this.userService.getTutorFilteredBy(search, subject, parsedPrice);
  }

  // GET /user/tutors/1234-abcd-5678
  @Get('tutor/:id')
  async getTutorDetail(@Param('id') id: string) {
    return this.userService.getTutorDetailProfile(id);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('tutor/verification')
  async submitVerification(
    @Request() req: any,
    @Body() dto: SubmitVerificationDto,
  ) {
    const userId = req.user.userId || req.user.sub;
    if (!userId) throw new UnauthorizedException('Identification missing in token');
    return this.userService.submitVerification(userId, dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('update/profile')
  async updateProfile(
    @Request() req: any,
    @Body() updateData: UpdateProfileDTO,
  ) {
    // Check multiple possible keys where the ID might be stored
    const userId = req.user.userId || req.user.sub || req.user.id;

    if (!userId) {
      console.error('ERROR: Could not find user ID in req.user:', req.user);
      throw new UnauthorizedException('Identification missing in token');
    }

    return this.userService.updateProfile(userId, updateData);
  }

  @Get()
  async getDummyData() {
    return {
      message: 'This is a dummy response from the UserController.',
      timestamp: new Date(),
    };
  }
}
