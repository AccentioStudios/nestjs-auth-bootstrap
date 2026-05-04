# Permission model

OAuth2 scope-style: `<RESOURCE>_<LEVEL>`. Three levels, one resource per
permission family.

## Levels

| Level | Covers | Example endpoints |
|-------|--------|-------------------|
| `READ` | List, get-one, search, view | `GET /users`, `GET /users/:id` |
| `WRITE` | Create, update, delete on the resource itself | `POST /users`, `PATCH /users/:id`, `DELETE /users/:id` |
| `MANAGE` | Admin ops *about* the resource: assign roles, lock/unlock, force-delete, audit access | `POST /users/:id/role`, `POST /users/:id/lock` |

**Rule of thumb**: if the operation changes who can do what (role assignment,
permission changes, lifting safety locks), it's MANAGE. If it's CRUD on the
resource fields, it's WRITE.

## Why three levels (not five)

Five-level (`READ/CREATE/UPDATE/DELETE/MANAGE`) sounds more granular but creates
real-world friction:

- Every new resource adds 5 enum members and 5 matrix entries instead of 3.
- Distinguishing CREATE from UPDATE rarely maps to a real user role — anyone
  who can create usually can update what they created.
- DELETE often becomes its own permission anyway via MANAGE.

Three levels matches OAuth2 scope conventions (`read`, `write`, `admin`) and
keeps the policy auditable at a glance. If a specific resource genuinely needs
to split DELETE off, add `<RESOURCE>_DELETE` as an extra member alongside the
three — the model handles it.

## Base resources

Always present:

- `USER` — accounts, profiles
- `ORGANIZATION` — tenant/org records (only meaningful in multi-tenant)

Project-specific resources are added via Phase 2 user input.

## Base roles

| Role | Scope | Default permissions |
|------|-------|---------------------|
| `SUPER_ADMIN` | System-wide | All permissions |
| `ADMIN` | Organization-wide | `USER_READ/WRITE/MANAGE`, `ORG_READ/WRITE` (no `ORG_MANAGE`) |
| `USER` | Self | `USER_READ` |

`SUPER_ADMIN` is the only role that can MANAGE organizations and assign
`SUPER_ADMIN` to others. This prevents the most common privilege-escalation
class.

## Adding a new resource — recipe

Goal: add `PROJECT` permissions.

1. **Edit `permission-policy.ts`**:
   ```ts
   export enum Permission {
     // ...existing
     PROJECT_READ   = 'project:read',
     PROJECT_WRITE  = 'project:write',
     PROJECT_MANAGE = 'project:manage',
   }
   ```
2. **Update `ROLE_PERMISSIONS`**:
   ```ts
   [UserRole.ADMIN]: [
     // ...existing
     Permission.PROJECT_READ,
     Permission.PROJECT_WRITE,
   ],
   [UserRole.USER]: [
     Permission.USER_READ,
     Permission.PROJECT_READ,
   ],
   ```
   (`SUPER_ADMIN` picks up the new permissions automatically via
   `Object.values(Permission)`.)
3. **Use in controllers**:
   ```ts
   @Post()
   @RequirePermission(Permission.PROJECT_WRITE)
   async create(...) { ... }
   ```

That's it. No guard changes, no module registration.

## Adding a new role — recipe

Goal: add `MODERATOR`.

1. **Edit `enums.ts`**:
   ```ts
   export enum UserRole {
     SUPER_ADMIN = 'SUPER_ADMIN',
     ADMIN       = 'ADMIN',
     MODERATOR   = 'MODERATOR',
     USER        = 'USER',
   }
   ```
2. **Update `ROLE_PERMISSIONS`** — define the moderator's permissions:
   ```ts
   [UserRole.MODERATOR]: [
     Permission.USER_READ,
     Permission.USER_WRITE,    // can edit users but not assign roles
     Permission.PROJECT_READ,
   ],
   ```
3. **Update `ASSIGNABLE_ROLES`** — who can assign MODERATOR, and to whom can a
   moderator assign?
   ```ts
   [UserRole.SUPER_ADMIN]: [SUPER_ADMIN, ADMIN, MODERATOR, USER],
   [UserRole.ADMIN]:       [ADMIN, MODERATOR, USER],
   [UserRole.MODERATOR]:   [USER],
   [UserRole.USER]:        [],
   ```
4. **Migrate existing users** if any should become moderators (DB update or
   seed).

That's it. Tokens issued for MODERATOR users will carry `role: 'MODERATOR'` and
`hasPermission` resolves naturally.
