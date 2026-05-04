import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { AuthService } from './auth.service{{IMPORT_EXT}}';
import { LoginDto } from './dto/login.dto{{IMPORT_EXT}}';
import { RefreshDto } from './dto/refresh.dto{{IMPORT_EXT}}';
import { AuthResponseDto } from './dto/auth-response.dto{{IMPORT_EXT}}';
import { MeResponseDto } from './dto/me-response.dto{{IMPORT_EXT}}';
import { Public } from '../../common/decorators/public.decorator{{IMPORT_EXT}}';
import { CurrentUser } from '../../common/decorators/current-user.decorator{{IMPORT_EXT}}';
import type { JwtPayload } from '../../common/decorators/current-user.decorator{{IMPORT_EXT}}';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    return this.authService.login(dto, req.ip);
  }

  @Get('me')
  async me(@CurrentUser() user: JwtPayload): Promise<MeResponseDto> {
    return this.authService.me(user.sub{{#if MULTI_TENANT}}, user.org{{/if}});
  }

  @Post('refresh')
  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async refresh(@Body() dto: RefreshDto): Promise<AuthResponseDto> {
    return this.authService.refresh(dto.refreshToken);
  }
}
