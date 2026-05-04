import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
{{#if ORM_MONGOOSE}}
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from './schemas/user.schema{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_TYPEORM}}
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_PRISMA}}
import { PrismaService } from '../../prisma/prisma.service{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_STUB}}
import { UserRepository } from './user.repository{{IMPORT_EXT}}';
{{/if}}
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto{{IMPORT_EXT}}';
import { AuthResponseDto } from './dto/auth-response.dto{{IMPORT_EXT}}';
import { MeResponseDto } from './dto/me-response.dto{{IMPORT_EXT}}';

@Injectable()
export class AuthService {
  constructor(
{{#if ORM_MONGOOSE}}
    @InjectModel(User.name) private readonly userModel: Model<User>,
{{/if}}
{{#if ORM_TYPEORM}}
    @InjectRepository(User) private readonly userRepo: Repository<User>,
{{/if}}
{{#if ORM_PRISMA}}
    private readonly prisma: PrismaService,
{{/if}}
{{#if ORM_STUB}}
    private readonly userRepository: UserRepository,
{{/if}}
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async login(dto: LoginDto, _ip?: string): Promise<AuthResponseDto> {
    const email = dto.email.toLowerCase();
{{#if ORM_MONGOOSE}}
    const user = await this.userModel.findOne({ email, deletedAt: null });
{{/if}}
{{#if ORM_TYPEORM}}
    const user = await this.userRepo.findOne({ where: { email } });
{{/if}}
{{#if ORM_PRISMA}}
    const user = await this.prisma.user.findUnique({ where: { email } });
{{/if}}
{{#if ORM_STUB}}
    const user = await this.userRepository.findByEmail(email);
{{/if}}
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.issueTokens(user);
  }

  async me(userId: string{{#if MULTI_TENANT}}, _orgId?: string{{/if}}): Promise<MeResponseDto> {
{{#if ORM_MONGOOSE}}
    const user = await this.userModel
      .findOne({ _id: userId, deletedAt: null })
      .select('-passwordHash')
      .lean();
{{/if}}
{{#if ORM_TYPEORM}}
    const user = await this.userRepo.findOne({ where: { id: userId } });
{{/if}}
{{#if ORM_PRISMA}}
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
{{/if}}
{{#if ORM_STUB}}
    const user = await this.userRepository.findById(userId);
{{/if}}
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      id: String((user as { _id?: string; id?: string })._id ?? (user as { id: string }).id),
      name: user.name,
      email: user.email,
      role: user.role,
{{#if MULTI_TENANT}}
      organizationId: user.organizationId,
{{/if}}
    };
  }

  async refresh(token: string): Promise<AuthResponseDto> {
    let payload: { sub: string; type?: string };
    try {
      payload = this.jwtService.verify(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Invalid token type');
    }

{{#if ORM_MONGOOSE}}
    const user = await this.userModel.findOne({ _id: payload.sub, deletedAt: null });
{{/if}}
{{#if ORM_TYPEORM}}
    const user = await this.userRepo.findOne({ where: { id: payload.sub } });
{{/if}}
{{#if ORM_PRISMA}}
    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
{{/if}}
{{#if ORM_STUB}}
    const user = await this.userRepository.findById(payload.sub);
{{/if}}
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    return this.issueTokens(user);
  }

  private issueTokens(user: {
    _id?: string;
    id?: string;
    role: string;
{{#if MULTI_TENANT}}
    organizationId?: string;
{{/if}}
  }): AuthResponseDto {
    const sub = String(user._id ?? user.id);
    const expiresIn = this.configService.get<string>('auth.jwtExpiration', '8h');
    const accessToken = this.jwtService.sign(
      {
        sub,
{{#if MULTI_TENANT}}
        org: user.organizationId,
{{/if}}
        role: user.role,
      },
      { expiresIn: expiresIn as unknown as number },
    );

    const refreshExpiresIn = this.configService.get<string>(
      'auth.jwtRefreshExpiration',
      '7d',
    );
    const refreshToken = this.jwtService.sign(
      { sub, type: 'refresh' },
      { expiresIn: refreshExpiresIn as unknown as number },
    );

    return { accessToken, refreshToken, expiresIn };
  }
}
