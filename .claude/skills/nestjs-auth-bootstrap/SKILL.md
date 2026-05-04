---
name: nestjs-auth-bootstrap
description: >
  Use this skill when the user asks to scaffold authentication, JWT auth, or
  role/permission-based authorization in a NestJS project. Triggers: "set up
  auth", "add JWT auth", "scaffold authentication", "necesito auth en mi proyecto
  NestJS", "crea sistema de roles y permisos", "bootstrap nestjs auth". The skill
  analyzes the target project, asks clarifying questions, installs dependencies,
  and scaffolds AuthModule + Passport JWT strategy + global CompositeAuthGuard +
  decorators (@Public, @RequirePermission, @CurrentUser) + OAuth2-style Permission
  enum (READ/WRITE/MANAGE per resource) + ROLE_PERMISSIONS matrix + refresh
  tokens + ThrottlerGuard. Generates target-project docs (CLAUDE.md section +
  docs/auth/EXTENDING.md) so future agents can extend the system without losing
  context.
metadata:
  domain: backend / nestjs / auth
  triggers: nestjs auth, jwt nestjs, scaffold authentication, roles permisos nestjs, bootstrap auth
  version: "0.1.0"
---

# nestjs-auth-bootstrap

Scaffold a complete NestJS authentication and authorization system into a target
project, replicating a battle-tested architecture: Passport+JWT strategies, a
single global `CompositeAuthGuard`, decorator-driven permission checks, and an
OAuth2-style Permission enum (READ/WRITE/MANAGE per resource).

## When to use

Trigger this skill when the user asks any of:

- "Add JWT auth to this NestJS project"
- "Scaffold an auth module with roles and permissions"
- "Necesito sistema de auth con roles en este NestJS"
- "Bootstrap auth in my Nest app"
- "Set up login + refresh + permission guards"

## When NOT to use

- Project is not NestJS (check `package.json` for `@nestjs/core`).
- User wants an external OAuth2 provider integration (Auth0, Cognito, Clerk) —
  this skill scaffolds first-party JWT auth, not federated identity.
- User only wants a single guard/decorator added to an existing auth system —
  point them at `docs/auth/EXTENDING.md` if it exists in the project, or
  to `references/permission-model.md` here.

## Non-negotiable design decisions

These are baked into the templates. If the user wants to deviate, complete the
skill first and then refactor — do not improvise mid-scaffold.

1. **One global guard**: `CompositeAuthGuard` registered via `APP_GUARD`. It
   handles `@Public` skip, JWT validation, and permission checks in one pass.
   No per-handler `@UseGuards()` stacking.
2. **Decorator-driven**: `@Public`, `@RequirePermission(...)`, `@CurrentUser()`
   are the only auth surface in handlers. `@Roles(...)` exists for legacy needs
   but `@RequirePermission` is preferred.
3. **OAuth2 scope-style permissions**: `<RESOURCE>_READ`, `<RESOURCE>_WRITE`,
   `<RESOURCE>_MANAGE`. WRITE = create+update+delete on the resource. MANAGE =
   admin operations (assigning roles, deleting any record, etc).
4. **Base roles**: `SUPER_ADMIN` (everything), `ADMIN` (READ+WRITE on user/org,
   no MANAGE on user roles), `USER` (READ on own resource). Extra roles via
   user input.
5. **Always included**: refresh tokens, `ThrottlerGuard`, global `ValidationPipe`
   with `{ whitelist: true, transform: true, forbidNonWhitelisted: true }`.
6. **NOT included by default**: account lockout, second auth strategy
   (team/api-key), audit logging. These have extension recipes in
   `docs/auth/EXTENDING.md` of the target project.
7. **Single login endpoint**: `POST /auth/login` serves all roles. Admin vs
   non-admin distinction is by permission checks on protected endpoints, not
   separate login flows.

## Workflow — 5 phases (BLOCKING)

Each phase blocks until the previous one is acknowledged. **Do not write
project files before Phase 4.**

### Phase 1 — Analyze

Use `Read`, `Glob`, `Grep` to inspect the target project. Collect:

- **NestJS presence + version**: `package.json` → `@nestjs/core` version.
- **Package manager**: presence of `package-lock.json` (npm), `pnpm-lock.yaml`
  (pnpm), or `yarn.lock` (yarn). Use whatever is present.
- **ORM**: presence of `mongoose`, `@nestjs/typeorm` + `typeorm`, or `prisma` +
  `@prisma/client` in `dependencies`.
- **Existing auth artifacts**: search for `AuthModule`, `JwtStrategy`,
  `JwtAuthGuard`, `permission-policy`, `@Public()`, `@RequirePermission`. List
  what exists and where.
- **Folder conventions**: read `src/` tree. Note if it uses `src/modules/`,
  `src/common/`, `src/core/` (preferred), or different layout.
- **`app.module.ts`**: read it; identify where to merge `AuthModule` import and
  `APP_GUARD` providers.
- **`main.ts`**: check whether `ValidationPipe` is already global.
- **`.env.example`**: check for existing `JWT_*` keys.

Report findings as a markdown table. Do not edit anything yet.

### Phase 2 — Ask

Use `AskUserQuestion` for adaptive clarification. Ask **only what could not be
inferred** in Phase 1. Always ask:

1. **If existing auth detected**: "Auth artifacts found at X. Abort, merge
   (extend existing), or overwrite?"
2. **If no ORM detected**: "No ORM found. Pick one: mongoose / TypeORM / Prisma
   (skill installs it), or generate stub repository (you wire it later)."
3. **Extra resources for Permission enum**: "Beyond `USER` and `ORGANIZATION`,
   list resources to add (e.g., `PROJECT`, `INVOICE`). Each gets READ/WRITE/MANAGE."
4. **Extra roles beyond SUPER_ADMIN/ADMIN/USER**: "Need additional roles?
   (e.g., MODERATOR, AUDITOR)"
5. **If folder layout differs**: "Project uses `<detected-layout>`. Confirm
   target paths for: auth module, common (guards/decorators), core (enums,
   authorization)."
6. **Multi-tenancy**: "Should JWT carry `org` claim and DTOs include
   `organizationId`? (yes for multi-tenant SaaS, no for single-tenant)."

### Phase 3 — Confirm

Print a single confirmation block listing:

- Files to create (full paths)
- Files to modify (`app.module.ts`, `main.ts`, `.env.example`, possibly
  `CLAUDE.md`)
- Dependencies to install (with the detected package manager command)
- Final shape of Permission enum and ROLE_PERMISSIONS matrix
- Final shape of UserRole enum

Wait for explicit OK. If the user requests changes, loop back to Phase 2.

### Phase 4 — Execute

Run in this order:

1. **Install dependencies** with the detected package manager:
   - Always: `@nestjs/jwt @nestjs/passport @nestjs/throttler @nestjs/config passport passport-jwt bcrypt class-validator class-transformer joi`
   - Always (dev): `@types/passport-jwt @types/bcrypt`
   - If installing mongoose: `@nestjs/mongoose mongoose`
   - If installing typeorm: `@nestjs/typeorm typeorm` + driver (ask which DB)
   - If installing prisma: `prisma @prisma/client` (also run `npx prisma init`
     if no schema.prisma)
2. **Render templates** from `templates/` with substitution. See
   `references/adaptation-matrix.md` for the variable map. Conditional sections
   use `{{#if ORM_MONGOOSE}} ... {{/if}}` style — render manually with simple
   string replacement, no template engine needed.
3. **Write files** to the target paths.
4. **Merge `app.module.ts`**: follow `templates/app-module.snippet.md`.
5. **Merge `main.ts`**: ensure `ValidationPipe` block exists.
6. **Append/create `.env.example`**: add JWT keys.
7. **Append `CLAUDE.md`**: add the "Authentication & Authorization" section
   from `templates/docs/CLAUDE-auth-section.md.tpl` (create the file if it
   doesn't exist).
8. **Create `docs/auth/EXTENDING.md`**: render from
   `templates/docs/EXTENDING.md.tpl` with the chosen role/resource names.

### Phase 5 — Verify

1. Run `npx tsc --noEmit` (or `npm run build`). Report errors verbatim. Fix
   trivial path issues (e.g., `.js` extension on imports for ESM projects vs
   no extension for CJS — detect from `tsconfig.json` `module` field).
2. List the new endpoints: `POST /auth/login`, `POST /auth/refresh`,
   `GET /auth/me`.
3. Suggest verification cURL commands (referencing
   `references/verification-checklist.md`).
4. Tell the user where `EXTENDING.md` lives and what it covers.

## Outputs

After a successful run the target project gains:

- `src/modules/auth/` — full module
- `src/common/guards/` — 4 guards
- `src/common/decorators/` — 4 decorators
- `src/core/enums.ts` (or appended) with `UserRole`
- `src/core/authorization/permission-policy.ts` with `Permission`,
  `ROLE_PERMISSIONS`, `ASSIGNABLE_ROLES`, helpers
- `src/config/auth.config.ts`
- Persistence layer (variant by ORM): `User` schema/entity/model
- Updated `app.module.ts`, `main.ts`, `.env.example`
- New/updated `CLAUDE.md` with auth section
- New `docs/auth/EXTENDING.md` runbook

## How to iterate this skill

This skill lives at `.claude/skills/nestjs-auth-bootstrap/` in the `arka-api`
repo. When you find a case the templates don't handle (new ORM, edge layout,
missing variable), update the relevant template or reference doc and bump
`metadata.version` in this file's frontmatter. Commit with a descriptive
message; the skill is meant to be a living artifact.
