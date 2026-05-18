import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getStatus(): string {
    return "Well i guess we have leak here, you supposed not to see this if you're not from our developer, pls report it if you find this";
  }
}
