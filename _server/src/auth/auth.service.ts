import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { hash, verify } from 'argon2';
import { OAuth2Client } from 'google-auth-library';
import { PrismaService } from 'src/prisma.service';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {
    this.googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
  }

  async signUp(email: string, pass: string, role: string = 'STUDENT') {
    const existingUser = await this.prisma.profiles.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new BadRequestException('Email already registered.');
    }

    const hashedPassword = await hash(pass);

    const newUser = await this.prisma.profiles.create({
      data: {
        email,
        password: hashedPassword,
        role: role.toUpperCase(),
        book_price: 0,
      },
    });

    return this.generateTokens(newUser.id, newUser.email!, newUser.role);
  }

  async login(email: string, pass: string) {
    const user = await this.prisma.profiles.findUnique({ where: { email } });
    if (!user) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const isValid = await verify(user.password!, pass);
    if (!isValid) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    return this.generateTokens(user.id, user.email!, user.role);
  }

  async googleLogin(idToken: string, role: string) {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new UnauthorizedException('Invalid Google token.');
      }

      const { email, name, picture } = payload;
      let user = await this.prisma.profiles.findUnique({ where: { email } });

      if (!user) {
        user = await this.prisma.profiles.create({
          data: {
            email,
            full_name: name,
            avatar_url: picture,
            role: role.toUpperCase(),
            book_price: 0,
          },
        });
      } else {
        const needsUpdate = (!user.full_name && name) || (!user.avatar_url && picture);
        if (needsUpdate) {
          user = await this.prisma.profiles.update({
            where: { email },
            data: {
              full_name: user.full_name || name,
              avatar_url: user.avatar_url || picture,
            },
          });
        }
      }

      const tokens = this.generateTokens(user.id, user.email!, user.role);
      return {
        ...tokens,
        user: {
          ...tokens.user,
          full_name: user.full_name,
          avatar_url: user.avatar_url,
        },
        message: 'Google login successful.',
      };
    } catch (e) {
      console.error('Google auth error:', e);
      throw new UnauthorizedException('Failed to authenticate with Google.');
    }
  }

  async getMe(userId: string) {
    const user = await this.prisma.profiles.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        role: true,
        overall_rating: true,
        rating_count: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    return user;
  }

  // ⚠️ TEMP — DEV ONLY. REMOVE BEFORE PRODUCTION / DEMO.
  async devToken(email: string) {
    const user = await this.prisma.profiles.findUnique({ where: { email } });
    if (!user) throw new NotFoundException(`No user with email: ${email}`);
    return {
      ...this.generateTokens(user.id, user.email!, user.role),
      warning: 'DEV TOKEN — remove /auth/dev-token endpoint before production',
    };
  }

  private generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    return {
      message: 'Authentication successful',
      access_token: this.jwtService.sign(payload),
      user: { id: userId, email, role },
    };
  }
}
