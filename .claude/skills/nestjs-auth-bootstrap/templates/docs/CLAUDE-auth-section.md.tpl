## Authentication & Authorization

This project uses a JWT-based auth system scaffolded by the
`nestjs-auth-bootstrap` skill. Single global `CompositeAuthGuard` orchestrates
auth and permission checks via decorator metadata.

### Stack

- **Strategy**: Passport JWT (`@nestjs/passport` + `passport-jwt`)
- **Token signing**: `@nestjs/jwt`
- **Rate limiting**: `@nestjs/throttler` (100/min global, stricter on `/auth/*`)
- **Password hashing**: `bcrypt`
- **Validation**: `class-validator` via global `ValidationPipe`

### Canonical files

| Concern | Path |
|---------|------|
| Auth module | `{{PATH_MODULES}}/auth/auth.module.ts` |
| Login + refresh + me | `{{PATH_MODULES}}/auth/auth.service.ts` |
| Endpoints | `{{PATH_MODULES}}/auth/auth.controller.ts` |
| JWT strategy | `{{PATH_MODULES}}/auth/strategies/jwt.strategy.ts` |
| Global auth guard | `{{PATH_COMMON}}/guards/composite-auth.guard.ts` |
| Decorators | `{{PATH_COMMON}}/decorators/{public,current-user,require-permission,roles}.decorator.ts` |
| Permission policy (single source of truth) | `{{PATH_CORE}}/authorization/permission-policy.ts` |
| Roles enum | `{{PATH_CORE}}/enums.ts` |

### Roles

`{{ROLES}}` — see `{{PATH_CORE}}/enums.ts`. Default policy:

- `SUPER_ADMIN` has every permission.
- `ADMIN` has READ + WRITE on every resource and MANAGE on USER.
- `USER` has READ on USER only.

Project-specific overrides live in `ROLE_PERMISSIONS` in
`{{PATH_CORE}}/authorization/permission-policy.ts`.

### Permission style

OAuth2 scope-style: `<RESOURCE>_READ`, `<RESOURCE>_WRITE`, `<RESOURCE>_MANAGE`.
Resources currently registered: `{{RESOURCES}}`.

- READ → list, get-one, view
- WRITE → create, update, delete on the resource itself
- MANAGE → admin operations *about* the resource (assign roles, lock, audit)

### Admin vs non-admin endpoints

There is **no** admin/non-admin split at the URL level. A handler is
"admin-only" iff it carries `@RequirePermission(Permission.X_MANAGE)` (or
similar). With no decorator, any authenticated user passes.

```ts
@Post()
@RequirePermission(Permission.USER_MANAGE)   // admin-only
async assignRole(...) { ... }

@Get(':id')
@RequirePermission(Permission.USER_READ)      // any role with READ
async getOne(...) { ... }

@Get('me')                                     // any authenticated user
async me(@CurrentUser() user: JwtPayload) { ... }
```

### How to extend

For recipes (add a new resource, role, second auth strategy, account lockout,
audit logging, multi-tenancy), see [`docs/auth/EXTENDING.md`](docs/auth/EXTENDING.md).
That file is the authoritative runbook for changes to the auth system.
