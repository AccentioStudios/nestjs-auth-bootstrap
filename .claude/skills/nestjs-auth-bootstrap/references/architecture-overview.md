# Architecture overview

## Request flow

```
HTTP Request
   │
   ▼
ThrottlerGuard (APP_GUARD)            ← rate-limit (100/min default)
   │
   ▼
CompositeAuthGuard (APP_GUARD)        ← single entry point for auth+authz
   │
   ├─ @Public() metadata?  ──── yes ─→ allow, hand to handler
   │
   ├─ @TeamAuth() metadata? ─── yes ─→ JwtTeamGuard (optional, opt-in)
   │
   └─ default ─────────────────────→ JwtAuthGuard
                                       │
                                       ▼
                                     Passport JwtStrategy
                                       │ verifies signature + expiry
                                       │ loads user from DB
                                       │ attaches { sub, org?, role } to req.user
                                       ▼
                                     check @RequirePermission(perm) metadata
                                       │
                                       ▼
                                     hasPermission(user.role, perm)
                                       │
                                       ├─ true  → handler
                                       └─ false → 403 ForbiddenException
```

## Pieces and their files

| Piece | File | Role |
|-------|------|------|
| Strategy | `src/modules/auth/strategies/jwt.strategy.ts` | Passport JWT validator. Verifies token, loads user, returns `{ sub, org?, role }` |
| Guard (composite) | `src/common/guards/composite-auth.guard.ts` | Single global guard orchestrating Public/JWT/permission checks |
| Guard (JWT) | `src/common/guards/jwt-auth.guard.ts` | Thin wrapper over `AuthGuard('jwt')` |
| Guard (permission) | `src/common/guards/permission.guard.ts` | Standalone version of permission check (rarely needed; CompositeAuthGuard already does it) |
| Guard (roles) | `src/common/guards/roles.guard.ts` | Legacy role list check; prefer `@RequirePermission` |
| Decorator `@Public` | `src/common/decorators/public.decorator.ts` | Bypass auth |
| Decorator `@RequirePermission` | `src/common/decorators/require-permission.decorator.ts` | Permission gate |
| Decorator `@CurrentUser` | `src/common/decorators/current-user.decorator.ts` | Param decorator for handlers; exports `JwtPayload` interface |
| Decorator `@Roles` | `src/common/decorators/roles.decorator.ts` | Legacy |
| Permission policy | `src/core/authorization/permission-policy.ts` | `Permission` enum, `ROLE_PERMISSIONS`, `ASSIGNABLE_ROLES`, `hasPermission`, `canAssignRole` |
| Roles enum | `src/core/enums.ts` | `UserRole` enum |
| Service | `src/modules/auth/auth.service.ts` | login, refresh, me — bcrypt + JWT sign |
| Controller | `src/modules/auth/auth.controller.ts` | 3 endpoints |
| Module | `src/modules/auth/auth.module.ts` | Wires PassportModule, JwtModule, ORM imports |
| Config | `src/config/auth.config.ts` | Env-backed JWT secret + expirations |

## Why one global guard?

Old NestJS recipes stack `@UseGuards(JwtAuthGuard, RolesGuard, PermissionGuard)`
on every protected handler. That:

- duplicates intent on every controller,
- runs three reflection passes,
- makes "is this endpoint public?" a multi-file question.

The composite guard fans out internally: read `@Public` first, then pick a JWT
strategy, then check permissions. Endpoints state their intent with **one**
decorator (`@RequirePermission(...)` or `@Public()`), nothing else.

## Why OAuth2 scope-style permissions?

`USER_READ`, `USER_WRITE`, `USER_MANAGE` reads naturally and aligns with
common authorization vocabulary. Three levels per resource is enough for 95% of
needs:

- **READ** — list, get-one, view.
- **WRITE** — create, update, delete (operations on the resource itself).
- **MANAGE** — admin operations *about* the resource: assigning roles, locking
  accounts, force-deletes, reading audit info.

If a project genuinely needs finer granularity (e.g., separate `INVOICE_REFUND`
permission), add it as an extra Permission member — the model is a flat enum,
extension is a single line.

## What "admin endpoint" means in practice

There is no `isAdmin` flag and no separate admin login. An "admin endpoint" is
just a handler with `@RequirePermission(Permission.X_MANAGE)`:

```ts
@Post()
@RequirePermission(Permission.USER_MANAGE)
async assignRole(...) { ... }
```

`SUPER_ADMIN` and `ADMIN` roles have `USER_MANAGE` in their permission set;
`USER` doesn't. The matrix at `permission-policy.ts` is the single source of
truth.
