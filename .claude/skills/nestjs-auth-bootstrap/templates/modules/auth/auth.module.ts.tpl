import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
{{#if ORM_MONGOOSE}}
import { MongooseModule } from '@nestjs/mongoose';
import { User, UserSchema } from './schemas/user.schema{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_TYPEORM}}
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_PRISMA}}
import { PrismaModule } from '../../prisma/prisma.module{{IMPORT_EXT}}';
{{/if}}
{{#if ORM_STUB}}
import { UserRepository } from './user.repository{{IMPORT_EXT}}';
{{/if}}
import { AuthController } from './auth.controller{{IMPORT_EXT}}';
import { AuthService } from './auth.service{{IMPORT_EXT}}';
import { JwtStrategy } from './strategies/jwt.strategy{{IMPORT_EXT}}';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('auth.jwtSecret'),
      }),
    }),
{{#if ORM_MONGOOSE}}
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
{{/if}}
{{#if ORM_TYPEORM}}
    TypeOrmModule.forFeature([User]),
{{/if}}
{{#if ORM_PRISMA}}
    PrismaModule,
{{/if}}
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
{{#if ORM_STUB}}
    UserRepository,
{{/if}}
  ],
  exports: [AuthService],
})
export class AuthModule {}
