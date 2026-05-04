import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
{{#if ORM_MONGOOSE}}
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../schemas/user.schema{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_TYPEORM}}
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_PRISMA}}
import { PrismaService } from '../../../prisma/prisma.service{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_STUB}}
import { UserRepository } from '../user.repository{{IMPORT_EXT}}';
{{/if}}
import { ExtractJwt, Strategy } from 'passport-jwt';

interface JwtPayloadRaw {
  sub: string;
{{#if MULTI_TENANT}}
  org?: string;
{{/if}}
  role: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    configService: ConfigService,
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
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: configService.getOrThrow<string>('auth.jwtSecret'),
    });
  }

  async validate(payload: JwtPayloadRaw) {
{{#if ORM_MONGOOSE}}
    const user = await this.userModel
      .findOne({ _id: payload.sub, deletedAt: null })
      .select('_id role{{#if MULTI_TENANT}} organizationId{{/if}}')
      .lean();
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
      throw new UnauthorizedException('User no longer active');
    }

    return {
      sub: String((user as { _id?: string; id?: string })._id ?? (user as { id: string }).id),
{{#if MULTI_TENANT}}
      org: (user as { organizationId?: string }).organizationId,
{{/if}}
      role: user.role,
    };
  }
}
