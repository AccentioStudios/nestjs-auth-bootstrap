import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator{{IMPORT_EXT}}';
import { PERMISSIONS_KEY } from '../decorators/require-permission.decorator{{IMPORT_EXT}}';
import { JwtAuthGuard } from './jwt-auth.guard{{IMPORT_EXT}}';
import {
  Permission,
  hasPermission,
} from '../../core/authorization/permission-policy{{IMPORT_EXT}}';
import { UserRole } from '../../core/enums{{IMPORT_EXT}}';

@Injectable()
export class CompositeAuthGuard implements CanActivate {
  private readonly jwtAuthGuard: JwtAuthGuard;

  constructor(private readonly reflector: Reflector) {
    this.jwtAuthGuard = new JwtAuthGuard();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (context.getType() === 'ws') return true;

    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    // ─────────────────────────────────────────────────────────
    // Add additional auth strategies here (team auth, api-key,
    // service-to-service). See docs/auth/EXTENDING.md.
    // Example:
    //   const isTeamAuth = this.reflector.getAllAndOverride<boolean>(
    //     IS_TEAM_AUTH_KEY,
    //     [context.getHandler(), context.getClass()],
    //   );
    //   if (isTeamAuth) {
    //     return this.jwtTeamGuard.canActivate(context) as Promise<boolean>;
    //   }
    // ─────────────────────────────────────────────────────────

    const jwtResult = await (this.jwtAuthGuard.canActivate(
      context,
    ) as Promise<boolean>);
    if (!jwtResult) return false;

    const requiredPermissions = this.reflector.getAllAndOverride<Permission[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredPermissions || requiredPermissions.length === 0) return true;

    const { user } = context
      .switchToHttp()
      .getRequest<{ user: { role: string } }>();
    const role = user.role as UserRole;
    const allowed = requiredPermissions.every((perm) =>
      hasPermission(role, perm),
    );
    if (!allowed) throw new ForbiddenException('Insufficient permissions');

    return true;
  }
}
