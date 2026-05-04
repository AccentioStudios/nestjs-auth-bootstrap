# Adaptation matrix

Maps user answers from Phase 2 → template variables → affected files.

## Template variables

Variables substituted in `templates/**/*.tpl` files. Replace literally with the
user-chosen value.

| Variable | Source | Example value | Notes |
|----------|--------|---------------|-------|
| `{{ROLES}}` | Phase 2 Q4 | `SUPER_ADMIN, ADMIN, USER` | Comma-separated list of role names. Always uppercase snake. |
| `{{RESOURCES}}` | Phase 2 Q3 | `USER, ORGANIZATION, PROJECT` | Comma-separated resource names. |
| `{{ORM}}` | Phase 1 + Phase 2 Q2 | `mongoose` / `typeorm` / `prisma` / `stub` | Picks persistence variant. |
| `{{MULTI_TENANT}}` | Phase 2 Q6 | `true` / `false` | Whether `org` claim and `organizationId` field are included. |
| `{{IMPORT_EXT}}` | Phase 1 (tsconfig) | `.js` / `''` | ESM projects use `.js` extensions in imports; CJS uses none. Detect from `tsconfig.json`'s `module` field. |
| `{{PATH_MODULES}}` | Phase 2 Q5 | `src/modules` | Where module folders live. |
| `{{PATH_COMMON}}` | Phase 2 Q5 | `src/common` | Where guards/decorators live. |
| `{{PATH_CORE}}` | Phase 2 Q5 | `src/core` | Where enums + authorization live. |
| `{{ROLE_PERMISSIONS_BODY}}` | Computed | (see below) | TS literal of the role→permissions matrix. |
| `{{ASSIGNABLE_ROLES_BODY}}` | Computed | (see below) | TS literal of role→assignable-roles matrix. |
| `{{PERMISSION_MEMBERS}}` | Computed | (see below) | TS enum body lines. |
| `{{USER_ROLE_MEMBERS}}` | Computed | (see below) | TS enum body lines for `UserRole`. |

## Computing `{{PERMISSION_MEMBERS}}`

For each resource in `{{RESOURCES}}`, emit three lines:

```ts
{RESOURCE}_READ   = '{resource}:read',
{RESOURCE}_WRITE  = '{resource}:write',
{RESOURCE}_MANAGE = '{resource}:manage',
```

Resource name lowercase for the string literal, uppercase for the enum key.

## Computing `{{USER_ROLE_MEMBERS}}`

For each role in `{{ROLES}}`:

```ts
{ROLE} = '{ROLE}',
```

## Computing `{{ROLE_PERMISSIONS_BODY}}`

Default policy (skill applies unless user overrides):

- `SUPER_ADMIN` → `Object.values(Permission)`
- `ADMIN` → `READ + WRITE + MANAGE` for `USER`, `READ + WRITE` for everything
  else.
- `USER` → `READ` for `USER` only.
- Custom roles → ask user OR start with `READ` for everything and let them
  refine in `EXTENDING.md`.

## Computing `{{ASSIGNABLE_ROLES_BODY}}`

Default:

- `SUPER_ADMIN` → all roles (including itself)
- `ADMIN` → all roles except `SUPER_ADMIN`
- Other roles → `[]` (cannot assign anything)

User can override during Phase 2.

## File ↔ template map

| Source template | Target path | Substitutions used |
|-----------------|-------------|-----|
| `templates/modules/auth/auth.module.ts.tpl` | `{{PATH_MODULES}}/auth/auth.module.ts` | `IMPORT_EXT`, `ORM` |
| `templates/modules/auth/auth.controller.ts.tpl` | `{{PATH_MODULES}}/auth/auth.controller.ts` | `IMPORT_EXT` |
| `templates/modules/auth/auth.service.ts.tpl` | `{{PATH_MODULES}}/auth/auth.service.ts` | `IMPORT_EXT`, `ORM`, `MULTI_TENANT` |
| `templates/modules/auth/strategies/jwt.strategy.ts.tpl` | `{{PATH_MODULES}}/auth/strategies/jwt.strategy.ts` | `IMPORT_EXT`, `ORM`, `MULTI_TENANT` |
| `templates/modules/auth/dto/login.dto.ts.tpl` | `{{PATH_MODULES}}/auth/dto/login.dto.ts` | none |
| `templates/modules/auth/dto/refresh.dto.ts.tpl` | `{{PATH_MODULES}}/auth/dto/refresh.dto.ts` | none |
| `templates/modules/auth/dto/auth-response.dto.ts.tpl` | `{{PATH_MODULES}}/auth/dto/auth-response.dto.ts` | none |
| `templates/modules/auth/dto/me-response.dto.ts.tpl` | `{{PATH_MODULES}}/auth/dto/me-response.dto.ts` | `MULTI_TENANT` |
| `templates/common/guards/composite-auth.guard.ts.tpl` | `{{PATH_COMMON}}/guards/composite-auth.guard.ts` | `IMPORT_EXT` |
| `templates/common/guards/jwt-auth.guard.ts.tpl` | `{{PATH_COMMON}}/guards/jwt-auth.guard.ts` | none |
| `templates/common/guards/permission.guard.ts.tpl` | `{{PATH_COMMON}}/guards/permission.guard.ts` | `IMPORT_EXT` |
| `templates/common/guards/roles.guard.ts.tpl` | `{{PATH_COMMON}}/guards/roles.guard.ts` | `IMPORT_EXT` |
| `templates/common/decorators/public.decorator.ts.tpl` | `{{PATH_COMMON}}/decorators/public.decorator.ts` | none |
| `templates/common/decorators/current-user.decorator.ts.tpl` | `{{PATH_COMMON}}/decorators/current-user.decorator.ts` | `MULTI_TENANT` |
| `templates/common/decorators/require-permission.decorator.ts.tpl` | `{{PATH_COMMON}}/decorators/require-permission.decorator.ts` | `IMPORT_EXT` |
| `templates/common/decorators/roles.decorator.ts.tpl` | `{{PATH_COMMON}}/decorators/roles.decorator.ts` | none |
| `templates/core/enums.ts.tpl` | `{{PATH_CORE}}/enums.ts` | `USER_ROLE_MEMBERS` |
| `templates/core/authorization/permission-policy.ts.tpl` | `{{PATH_CORE}}/authorization/permission-policy.ts` | `IMPORT_EXT`, `PERMISSION_MEMBERS`, `ROLE_PERMISSIONS_BODY`, `ASSIGNABLE_ROLES_BODY` |
| `templates/persistence/{ORM}/...` | varies by ORM | varies |
| `templates/config/auth.config.ts.tpl` | `src/config/auth.config.ts` | none |
| `templates/config/env.example.tpl` | `.env.example` (append if exists) | none |
| `templates/docs/CLAUDE-auth-section.md.tpl` | `CLAUDE.md` (append, create if missing) | `ROLES`, `RESOURCES`, `PATH_*` |
| `templates/docs/EXTENDING.md.tpl` | `docs/auth/EXTENDING.md` | `ROLES`, `RESOURCES`, `PATH_*` |

## Conditional sections in templates

Some templates contain blocks like:

```ts
{{#if MULTI_TENANT}}
  org: user.organizationId,
{{/if}}
```

Render rule: keep the inner block if the variable is truthy, else strip the
whole `{{#if X}}...{{/if}}` region (including the markers themselves and the
newline after each marker).

Variables that gate blocks: `MULTI_TENANT`, `ORM_MONGOOSE`, `ORM_TYPEORM`,
`ORM_PRISMA`, `ORM_STUB`. Set the corresponding flag truthy based on Phase 1
detection / Phase 2 answer.

## Existing-auth merge mode

When the user picks "merge" in Phase 2 Q1:

- **Skip** writing files that already exist; instead, diff against the template
  and propose patches.
- **Always** write the docs (`EXTENDING.md`, CLAUDE.md section) — those are
  pure additions.
- **Always** ensure `permission-policy.ts` and the Permission enum match what
  the docs claim. If the existing policy uses different conventions, surface
  this as a decision for the user — do not silently rewrite.
