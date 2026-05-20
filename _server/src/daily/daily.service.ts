import { Injectable, InternalServerErrorException } from '@nestjs/common';

@Injectable()
export class DailyService {
  private readonly apiKey = process.env.DAILY_API_KEY;
  private readonly domain = process.env.DAILY_DOMAIN; // e.g. yourapp.daily.co
  private readonly base = 'https://api.daily.co/v1';

  private get headers() {
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.apiKey}`,
    };
  }

  private devMode() {
    return !this.apiKey || !this.domain;
  }

  // Create a private Daily.co room for a booking. Called once on confirm.
  async createRoom(bookingId: string, sessionEndAt: Date): Promise<string> {
    if (this.devMode()) return `dev-room-${bookingId}`;

    // Room expires 2 hours after session ends
    const exp = Math.floor(sessionEndAt.getTime() / 1000) + 7_200;
    const res = await fetch(`${this.base}/rooms`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        name: `studyapp-${bookingId}`,
        privacy: 'private',
        properties: { exp },
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new InternalServerErrorException(`Daily room creation failed: ${err}`);
    }

    const data = await res.json() as { name: string };
    return data.name;
  }

  // Mint a participant or owner token. Called on every join request.
  async createToken(
    roomName: string,
    userId: string,
    sessionEndAt: Date,
    isOwner = false,
  ): Promise<{ token: string; room_url: string }> {
    if (this.devMode()) {
      return {
        token: `dev-token-${userId}`,
        room_url: `https://meet.jit.si/${roomName}`, // fallback to Jitsi in dev
      };
    }

    // Token expires 30 min after session ends
    const exp = Math.floor(sessionEndAt.getTime() / 1000) + 1_800;
    const res = await fetch(`${this.base}/meeting-tokens`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        properties: {
          room_name: roomName,
          user_id: userId,
          is_owner: isOwner,
          exp,
        },
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new InternalServerErrorException(`Daily token creation failed: ${err}`);
    }

    const data = await res.json() as { token: string };
    return {
      token: data.token,
      room_url: `https://${this.domain}/${roomName}`,
    };
  }
}
