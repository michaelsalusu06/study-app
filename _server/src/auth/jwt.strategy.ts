import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private prisma: PrismaService) {
    super({
      // Look for the token in the Authorization header as a Bearer token
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET!, // Must match your .env file
    });
  }

  // This function ONLY runs if the token's signature is valid
  async validate(payload: any) {
    // payload.sub is the user ID we packed into the token during login/signup
    const user = await this.prisma.profiles.findUnique({
      where: { id: payload.sub },
    });

    if (!user) {
      throw new UnauthorizedException('User not found or token is invalid.');
    }

    if (user.is_banned) {
      throw new ForbiddenException('Account permanently banned.');
    }
    if (!user.is_active) {
      throw new ForbiddenException('Account deactivated. Contact support.');
    }

    // fire-and-forget: update last_seen without blocking the request
    this.prisma.profiles
      .update({ where: { id: payload.sub }, data: { last_seen_at: new Date() } })
      .catch(() => {});

    return {
      userId: payload.sub,
      email: payload.email,
      role: payload.role,
    };
  }
}
