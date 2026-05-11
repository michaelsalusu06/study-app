import { Body, Controller, ForbiddenException, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { SignUpDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Get()
  checkPath() {
    return "You're at the right path, continue!";
  }

  @Post('signup')
  signUp(@Body() body: SignUpDto) {
    return this.authService.signUp(body.email, body.password, body.role);
  }

  @Post('login')
  login(@Body() body: LoginDto) {
    return this.authService.login(body.email, body.password);
  }

  @Post('google')
  googleLogin(@Body() body: GoogleAuthDto) {
    return this.authService.googleLogin(body.idToken, body.role);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me')
  getMe(@Request() req: any) {
    const userId = req.user.userId || req.user.sub;
    return this.authService.getMe(userId);
  }

  // ⚠️ TEMP — DEV ONLY. REMOVE THIS BEFORE PRODUCTION / DEMO.
  // Returns a real JWT for any existing user email without password.
  // Only works when NODE_ENV !== 'production'.
  // Usage: GET /auth/dev-token?email=you@example.com
  @Get('dev-token')
  async devToken(@Request() req: any) {
    if (process.env.NODE_ENV === 'production') {
      throw new ForbiddenException('Not available in production.');
    }
    const email = req.query?.email as string;
    if (!email) throw new ForbiddenException('Provide ?email=...');
    return this.authService.devToken(email);
  }
}
