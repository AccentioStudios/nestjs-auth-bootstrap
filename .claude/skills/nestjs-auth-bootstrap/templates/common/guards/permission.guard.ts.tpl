import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/require-permission.decorator{{IMPORT_EXT}}';
import {
  Permission,
  hasPermission,
} from '../../core/authorization/permission-policy{{IMPORT_EXT}}';
import { UserRole } from '../../core/enums{{IMPORT_EXT}}';

/**
 * Standalone permission guard. Usually unnecessary because
 * CompositeAuthGuard already runs the same check globally. Provided for
 * scenarios where a route bypasses CompositeAuthGuard (rare).
 */
@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.getAllAndOverride<Permission[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const { user } = context
      .switchToHttp()
      .getRequest<{ user: { role: string } }>();

    const role = user.role as UserRole;
    const allowed = requiredPermissions.every((perm) =>
      hasPermission(role, perm),
    );

    if (!allowed) {
      throw new ForbiddenException('Insufficient permissions');
    }

    return true;
  }
}
