import { registerAs } from '@nestjs/config';

export default registerAs('auth', () => ({
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiration: process.env.JWT_EXPIRATION ?? '8h',
  jwtRefreshExpiration: process.env.JWT_REFRESH_EXPIRATION ?? '7d',
}));
