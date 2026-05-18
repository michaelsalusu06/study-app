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
    const normalizedRole = role.toUpperCase();
    const isTutor = normalizedRole === 'TUTOR';
    const isStudent = normalizedRole === 'STUDENT';
    const WELCOME_COINS = 10;

    const newUser = await this.prisma.profiles.create({
      data: {
        email,
        password: hashedPassword,
        role: normalizedRole,
        book_price: 0,
        ...(isTutor && { verification_status: 'PENDING' }),
        ...(isStudent && { coins_balance: WELCOME_COINS }),
      },
    });

    if (isStudent) {
      await this.prisma.coin_transactions.create({
        data: {
          profile_id: newUser.id,
          amount: WELCOME_COINS,
          kind: 'WELCOME_BONUS',
          note: 'Welcome bonus on registration',
        },
      });
    }

    return {
      ...this.generateTokens(newUser.id, newUser.email!, newUser.role),
      ...(isStudent && { coins_balance: WELCOME_COINS }),
      ...(isTutor && {
        verification_status: 'PENDING',
        notice: 'Your tutor account is pending admin review.',
      }),
    };
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

    return {
      ...this.generateTokens(user.id, user.email!, user.role),
      ...(user.verification_status && { verification_status: user.verification_status }),
    };
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
        verification_status: true,
        overall_rating: true,
        rating_count: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    return user;
  }

  async adminLogin(adminId: string, pass: string) {
    const user = await this.prisma.profiles.findUnique({ where: { admin_id: adminId } });
    if (!user || user.role !== 'ADMIN') {
      throw new UnauthorizedException('Invalid admin ID or password.');
    }

    const isValid = await verify(user.password!, pass);
    if (!isValid) {
      throw new UnauthorizedException('Invalid admin ID or password.');
    }

    return {
      ...this.generateTokens(user.id, adminId, user.role),
      admin: {
        id: user.id,
        admin_id: user.admin_id,
        full_name: user.full_name,
        role: user.role,
      },
    };
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
