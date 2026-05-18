/**
 * JWT payload shape for access and refresh tokens.
 */
export interface JwtPayloadDto {
  sub: number;
  email: string;
  type: 'access' | 'refresh';
  systemAdmin: boolean;
  isPinChanged: boolean;
}
