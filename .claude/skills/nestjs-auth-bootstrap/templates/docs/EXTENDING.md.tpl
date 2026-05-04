# Extending the auth system

This is the authoritative runbook for changes to authentication and
authorization in this project. Follow these recipes to keep the system
coherent.

Currently registered:

- **Roles**: `{{ROLES}}` — see `{{PATH_CORE}}/enums.ts`
- **Resources** (each has READ/WRITE/MANAGE): `{{RESOURCES}}` — see
  `{{PATH_CORE}}/authorization/permission-policy.ts`
- **Single global guard**: `CompositeAuthGuard` registered in
  `app.module.ts` via `APP_GUARD`. It routes through `@Public` skip → JWT
  validation → `@RequirePermission` check.

## Quick lookup

| You want to… | Edit | See section |
|--------------|------|-------------|
| Add a permission for a new resource | `permission-policy.ts` | [§1](#1-add-a-new-resource-to-the-permission-system) |
| Add a new role | `enums.ts`, `permission-policy.ts` | [§2](#2-add-a-new-role) |
| Add a second auth strategy (team / api-key) | `strategies/`, `composite-auth.guard.ts`, decorator | [§3](#3-add-a-second-auth-strategy) |
| Add account lockout | `auth.service.ts`, user schema/entity | [§4](#4-add-account-lockout) |
| Add audit logging | `auth.service.ts`, new `AuditLogService` | [§5](#5-add-audit-logging) |
| Add refresh token rotation / blacklist | `auth.service.ts`, Redis or DB | [§6](#6-add-refresh-token-rotation-or-blacklist) |
| Add multi-tenancy (org claim) | JWT payload, DTOs, services | [§7](#7-add-multi-tenancy) |

---

## 1. Add a new resource to the permission system

Example: add `PROJECT` (READ/WRITE/MANAGE).

### 1.1 Edit `{{PATH_CORE}}/authorization/permission-policy.ts`

```ts
export enum Permission {
  // ...existing
  PROJECT_READ   = 'project:read',
  PROJECT_WRITE  = 'project:write',
  PROJECT_MANAGE = 'project:manage',
}
```

### 1.2 Update `ROLE_PERMISSIONS`

```ts
export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
  [UserRole.SUPER_ADMIN]: Object.values(Permission), // automatic

  [UserRole.ADMIN]: [
    // ...existing
    Permission.PROJECT_READ,
    Permission.PROJECT_WRITE,
  ],

  [UserRole.USER]: [
    Permission.USER_READ,
    Permission.PROJECT_READ,  // if appropriate
  ],
};
```

### 1.3 Use in controllers

```ts
import { RequirePermission } from '{{PATH_COMMON}}/decorators/require-permission.decorator';
import { Permission } from '{{PATH_CORE}}/authorization/permission-policy';

@Controller('projects')
export class ProjectsController {
  @Get()
  @RequirePermission(Permission.PROJECT_READ)
  async list() { ... }

  @Post()
  @RequirePermission(Permission.PROJECT_WRITE)
  async create() { ... }

  @Delete(':id')
  @RequirePermission(Permission.PROJECT_WRITE)
  async remove() { ... }

  @Post(':id/transfer-owner')
  @RequirePermission(Permission.PROJECT_MANAGE)
  async transferOwner() { ... }
}
```

### 1.4 Update `CLAUDE.md`

Add `PROJECT` to the list of registered resources in the
"Authentication & Authorization" section.

---

## 2. Add a new role

Example: add `MODERATOR` between `ADMIN` and `USER`.

### 2.1 Edit `{{PATH_CORE}}/enums.ts`

```ts
export enum UserRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  ADMIN       = 'ADMIN',
  MODERATOR   = 'MODERATOR',  // new
  USER        = 'USER',
}
```

### 2.2 Edit `permission-policy.ts` — `ROLE_PERMISSIONS`

```ts
[UserRole.MODERATOR]: [
  Permission.USER_READ,
  Permission.USER_WRITE,        // can edit users
  // intentionally NO USER_MANAGE → can't change roles
  Permission.PROJECT_READ,
],
```

### 2.3 Edit `permission-policy.ts` — `ASSIGNABLE_ROLES`

Decide who can assign MODERATOR and to whom.

```ts
export const ASSIGNABLE_ROLES: Record<UserRole, UserRole[]> = {
  [UserRole.SUPER_ADMIN]: [SUPER_ADMIN, ADMIN, MODERATOR, USER],
  [UserRole.ADMIN]:       [ADMIN, MODERATOR, USER],
  [UserRole.MODERATOR]:   [USER],   // moderators can promote users
  [UserRole.USER]:        [],
};
```

### 2.4 Migrate existing data

If existing users should become moderators, write a migration or one-off
script. Don't do this through the UI by hand — keep the change auditable.

### 2.5 Update `CLAUDE.md`

Add `MODERATOR` to the role list.

---

## 3. Add a second auth strategy

Use case: bot/team tokens, API keys, machine-to-machine auth.

### 3.1 Create the strategy

`{{PATH_MODULES}}/auth/strategies/jwt-team.strategy.ts`:

```ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

interface JwtTeamPayloadRaw {
  sub: string;
  session: string;
  role: string;
}

@Injectable()
export class JwtTeamStrategy extends PassportStrategy(Strategy, 'jwt-team') {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: configService.getOrThrow<string>('auth.jwtSecret'),
    });
  }

  async validate(payload: JwtTeamPayloadRaw) {
    if (payload.role !== 'TEAM') {
      throw new UnauthorizedException('Invalid token role');
    }
    return { sub: payload.sub, session: payload.session, role: 'TEAM' };
  }
}
```

### 3.2 Create the guard

`{{PATH_COMMON}}/guards/jwt-team.guard.ts`:

```ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtTeamGuard extends AuthGuard('jwt-team') {
  handleRequest<T>(err: Error | null, user: T): T {
    if (err || !user) throw new UnauthorizedException('Invalid team token');
    return user;
  }
}
```

### 3.3 Create the marker decorator

`{{PATH_COMMON}}/decorators/team-auth.decorator.ts`:

```ts
import { SetMetadata } from '@nestjs/common';
export const IS_TEAM_AUTH_KEY = 'isTeamAuth';
export const TeamAuth = () => SetMetadata(IS_TEAM_AUTH_KEY, true);
```

### 3.4 Wire into `CompositeAuthGuard`

Edit `{{PATH_COMMON}}/guards/composite-auth.guard.ts` — add the team-auth
branch **before** the default JwtAuthGuard:

```ts
// near the top, alongside other imports
import { IS_TEAM_AUTH_KEY } from '../decorators/team-auth.decorator';
import { JwtTeamGuard } from './jwt-team.guard';

// in the constructor:
this.jwtTeamGuard = new JwtTeamGuard();

// in canActivate(), after the @Public check:
const isTeamAuth = this.reflector.getAllAndOverride<boolean>(
  IS_TEAM_AUTH_KEY,
  [context.getHandler(), context.getClass()],
);
if (isTeamAuth) {
  return this.jwtTeamGuard.canActivate(context) as Promise<boolean>;
}
```

### 3.5 Register the strategy in `AuthModule`

Add `JwtTeamStrategy` to the `providers` array.

### 3.6 Use it

```ts
@Controller('game')
@TeamAuth()  // controller-level: every endpoint requires team token
export class GameController {
  @Get('state')
  async getState(@CurrentUser() user: JwtPayload) { ... }
}
```

---

## 4. Add account lockout

Defends against credential stuffing.

### 4.1 Add fields to user schema/entity

- `failedLoginAttempts: number` (default 0)
- `lockedUntil: Date | null`

### 4.2 Add policy constants

`{{PATH_CORE}}/constants/password-policy.ts`:

```ts
export const ACCOUNT_LOCKOUT_THRESHOLD = 5;
export const ACCOUNT_LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 min
export const BCRYPT_SALT_ROUNDS = 12;
```

### 4.3 Edit `AuthService.login()`

Before bcrypt compare:

```ts
if (user.lockedUntil && user.lockedUntil.getTime() > Date.now()) {
  throw new UnauthorizedException('Account temporarily locked');
}
```

After bcrypt fail:

```ts
const attempts = (user.failedLoginAttempts ?? 0) + 1;
const update: Record<string, unknown> = { failedLoginAttempts: attempts };
if (attempts >= ACCOUNT_LOCKOUT_THRESHOLD) {
  update.lockedUntil = new Date(Date.now() + ACCOUNT_LOCKOUT_DURATION_MS);
}
// persist update via your ORM
```

After bcrypt success:

```ts
if (user.failedLoginAttempts > 0 || user.lockedUntil) {
  // reset to 0 / null
}
```

---

## 5. Add audit logging

### 5.1 Create `AuditLogService`

Write a service with methods like `logAuth(action, actorId, metadata)` that
inserts into an `audit_logs` collection/table.

### 5.2 Inject into `AuthService`

Log on: `LOGIN_SUCCESS`, `LOGIN_FAILED`, `ACCOUNT_LOCKED`, `REFRESH`.

### 5.3 Inject into `CompositeAuthGuard`

Log permission denials with `actorId`, `permission`, `path`, `ip`.

Don't block the request on log failures — wrap in try/catch and log to stderr
on persistence error.

---

## 6. Add refresh token rotation or blacklist

The default scaffold issues short-lived access tokens (8h) + refresh tokens
(7d). It does **not** revoke old refresh tokens on use, so a stolen refresh
token works until expiry.

To mitigate:

### Option A — rotation

On `/auth/refresh`, mark the old refresh token's `jti` as used in Redis with
TTL = remaining lifetime. Reject reuse.

### Option B — blacklist

Maintain a `revoked_tokens` table. On logout or password change, write the
`jti` with TTL. Strategy validates against the table.

Both options require including `jti` in JWT payload (use UUIDv4) and adding a
small Redis (or DB) check in `JwtStrategy.validate()`.

---

## 7. Add multi-tenancy

If the project initially scaffolded as single-tenant and now needs orgs:

### 7.1 Add `Organization` model + repo (whatever ORM is in use).

### 7.2 Add `organizationId` to User.

### 7.3 Update JWT payload

In `AuthService.issueTokens()`:

```ts
this.jwtService.sign({ sub, org: user.organizationId, role: user.role }, ...);
```

### 7.4 Update `JwtStrategy.validate()`

Return `{ sub, org, role }`.

### 7.5 Update `CurrentUser` decorator's `JwtPayload` interface

Add `org?: string`.

### 7.6 Filter queries by `user.org` in services

Every query that returns tenant-scoped data must filter `organizationId`. The
permission system does **not** do this — it's the service layer's job. Audit
existing controllers to ensure they pass `user.org` into the service.

---

## Anti-patterns to avoid

- **Don't stack `@UseGuards(JwtAuthGuard, RolesGuard, PermissionGuard)`** on
  individual handlers. The global `CompositeAuthGuard` already handles all
  three concerns. Stacking guards re-runs JWT validation and creates
  inconsistent auth surfaces.
- **Don't add `isAdmin` flags** on User. The permission system replaces this.
- **Don't create separate `/admin/*` controllers** with different auth
  middleware. Use `@RequirePermission(...MANAGE)` on the existing controller.
- **Don't bypass the policy in services** by hard-coding role checks
  (`if (user.role === 'ADMIN')`). Always go through `hasPermission(role,
  Permission.X)` so the matrix stays the single source of truth.
- **Don't issue tokens with extra claims** beyond `{ sub, role, org? }` unless
  you also update `JwtStrategy.validate()` to verify them. Extra claims that
  aren't validated are just lies.
