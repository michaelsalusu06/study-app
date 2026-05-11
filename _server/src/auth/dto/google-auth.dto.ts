import { IsIn, IsString } from 'class-validator';

export class GoogleAuthDto {
  @IsString()
  idToken: string;

  @IsIn(['STUDENT', 'TUTOR', 'student', 'tutor'])
  role: string;
}
