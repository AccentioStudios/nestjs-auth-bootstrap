# nestjs-auth-bootstrap

> Scaffold a production-ready NestJS authentication & authorization system in any project — Passport JWT, OAuth2-style permissions, role policy, refresh tokens, throttling, and self-extending docs — in one guided run.

A Claude Code skill that drops a battle-tested auth architecture into a target NestJS project. It analyzes the project first, asks only what it can't infer, installs the right dependencies for your stack, and scaffolds the canonical files. It also writes a `CLAUDE.md` section and a `docs/auth/EXTENDING.md` runbook so future Claude sessions know how to extend the system without losing context.

---

## What it scaffolds

- **`AuthModule`** — Passport + `@nestjs/jwt`, single login endpoint for all roles
- **3 endpoints** — `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`
- **One global guard** — `CompositeAuthGuard` registered via `APP_GUARD` (no per-handler guard stacking)
- **4 decorators** — `@Public`, `@RequirePermission`, `@CurrentUser`, `@Roles`
- **OAuth2-style Permission enum** — `<RESOURCE>_READ / WRITE / MANAGE` per resource
- **Roles + policy matrix** — `SUPER_ADMIN / ADMIN / USER` (extendable), `ROLE_PERMISSIONS`, `ASSIGNABLE_ROLES`, `hasPermission`, `canAssignRole`
- **Refresh tokens** with `type: 'refresh'` claim
- **`ThrottlerGuard`** — global rate limiting + tighter limits on `/auth/*`
- **`ValidationPipe`** — global `{ whitelist, transform, forbidNonWhitelisted }`
- **Persistence layer** — variant per ORM: Mongoose schema / TypeORM entity / Prisma model / stub repository
- **Self-documenting** — appends a section to your `CLAUDE.md` and creates `docs/auth/EXTENDING.md` with recipes for adding resources, roles, second auth strategies, account lockout, audit logging, refresh rotation, and multi-tenancy

---

## Installation

### Via Claude Code plugin manager (recommended)

This repo ships as a plugin: marketplace manifest at `.claude-plugin/marketplace.json`, plugin manifest at `.claude-plugin/plugin.json`, slash commands at `.claude/commands/`, and the skill at `.claude/skills/nestjs-auth-bootstrap/`.

Inside any Claude Code session:

```bash
/plugin marketplace add accentiostudios/nestjs-auth-bootstrap
/plugin menu
```

Then enable **nestjs-auth-bootstrap** from the menu. The skill auto-loads on matching prompts; the slash commands become available immediately.

Manage afterwards:

```bash
/plugin list                                          # what's installed
/plugin update accentiostudios/nestjs-auth-bootstrap  # pull latest
/plugin disable nestjs-auth-bootstrap                 # turn off without removing
/plugin remove accentiostudios/nestjs-auth-bootstrap  # uninstall
```

#### Slash commands exposed by the plugin

| Command | Purpose |
|---|---|
| `/bootstrap-auth` | Full 5-phase scaffold: analyze → ask → confirm → execute → verify. |
| `/analyze-auth` | Phase 1 only — reports project state without writing files. |
| `/extend-auth` | Add a resource, role, or recipe to an existing install via `EXTENDING.md`. |

The skill also auto-triggers on natural prompts (see [Usage](#usage)) — slash commands are just deterministic shortcuts.

### As a project-local skill (manual, no plugin)

Drop the whole `nestjs-auth-bootstrap/` folder into your project's `.claude/skills/` directory:

```
your-project/
├── .claude/
│   └── skills/
│       └── nestjs-auth-bootstrap/
│           ├── SKILL.md
│           ├── references/
│           └── templates/
└── ...
```

Claude auto-discovers skills under `.claude/skills/` — no settings file edit needed. Commit it; everyone on the team gets it.

### As a user-global skill

Copy the folder to `~/.claude/skills/nestjs-auth-bootstrap/`. It becomes available across all your projects.

---

## Usage

In a Claude Code session inside a NestJS project, say:

> "Scaffold NestJS auth with roles and permissions"

…or any of:

- "Add JWT auth to this NestJS project"
- "Set up login + refresh + permission guards"
- "Necesito sistema de auth con roles en este NestJS"
- "Bootstrap auth in my Nest app"

Claude will pick up the skill and run a 5-phase workflow:

| Phase | What happens |
|-------|--------------|
| 1. **Analyze** | Reads `package.json`, `app.module.ts`, `main.ts`, `tsconfig.json`. Detects NestJS version, package manager, ORM, existing auth artifacts, folder layout. Reports findings. |
| 2. **Ask** | Asks only what it can't infer: existing-auth strategy (abort/merge/overwrite), ORM if none detected, extra resources beyond `USER`/`ORGANIZATION`, extra roles, multi-tenant or not. |
| 3. **Confirm** | Shows the exact list of files to create/modify and dependencies to install. Waits for OK. |
| 4. **Execute** | Installs deps with the detected package manager, renders templates, merges `app.module.ts`, appends `CLAUDE.md`, creates `docs/auth/EXTENDING.md`. |
| 5. **Verify** | Runs `tsc --noEmit`, lists registered routes, suggests cURL smoke tests. |

The skill writes **nothing** before Phase 4. Each phase blocks until the previous one is acknowledged.

---

## Permission model — at a glance

OAuth2-style scopes, three levels per resource:

| Level | Use for |
|-------|---------|
| `READ` | List, get-one, view |
| `WRITE` | Create, update, delete on the resource itself |
| `MANAGE` | Admin operations *about* the resource (assign roles, lock accounts, force-delete, audit access) |

Default role policy:

| Role | Permissions |
|------|-------------|
| `SUPER_ADMIN` | All |
| `ADMIN` | `USER_READ/WRITE/MANAGE`, `ORG_READ/WRITE` (no `ORG_MANAGE`) |
| `USER` | `USER_READ` |

`SUPER_ADMIN` is the only role that can MANAGE organizations and assign `SUPER_ADMIN` to others.

### Admin vs non-admin endpoints — there's no split

A handler is "admin-only" iff it carries `@RequirePermission(Permission.X_MANAGE)`. No `/admin/*` URL prefix, no separate login, no `isAdmin` flag.

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

---

## Supported stacks

| Concern | Supported |
|---------|-----------|
| **NestJS** | v10 and v11 |
| **Package manager** | npm, pnpm, yarn (auto-detected from lockfile) |
| **Module system** | ESM (`module: NodeNext / Node16 / ESNext`) and CJS — import extension auto-applied |
| **ORM** | Mongoose, TypeORM, Prisma, or stub repository (you wire your own) |
| **Multi-tenancy** | Optional `org` claim + `organizationId` field (asked at Phase 2) |

---

## What the skill **does not** do (by design)

These are documented in the generated `docs/auth/EXTENDING.md` with full code recipes — opt in only when you need them:

- Account lockout after N failed logins
- Audit logging (login success/fail, permission denials)
- Second auth strategy (team tokens, API keys, M2M)
- Refresh token rotation / blacklist
- Multi-tenant scoping enforcement at the service layer
- External OAuth provider integration (Auth0, Cognito, Clerk) — use a different skill for federated identity

---

## File structure of this skill

```
nestjs-auth-bootstrap/
├── SKILL.md                                  # frontmatter + 5-phase workflow
├── references/
│   ├── architecture-overview.md              # request flow + responsibilities
│   ├── permission-model.md                   # READ/WRITE/MANAGE rationale + recipes
│   ├── adaptation-matrix.md                  # variable map for template rendering
│   └── verification-checklist.md             # post-scaffold smoke tests
└── templates/
    ├── modules/auth/                         # module, controller, service, strategy, DTOs
    ├── common/guards/                        # composite, jwt-auth, permission, roles
    ├── common/decorators/                    # public, current-user, require-permission, roles
    ├── core/                                 # enums.ts.tpl, authorization/permission-policy.ts.tpl
    ├── persistence/{mongoose,typeorm,prisma,stub}/
    ├── config/                               # auth.config + env.example
    ├── app-module.snippet.md                 # merge instructions for app.module.ts
    └── docs/                                 # CLAUDE.md section + EXTENDING.md runbook
```

---

## Generated outputs in your project

After a successful run:

```
your-project/
├── src/
│   ├── modules/auth/                         # full auth module
│   ├── common/guards/                        # 4 guards
│   ├── common/decorators/                    # 4 decorators
│   ├── core/enums.ts                         # UserRole
│   ├── core/authorization/permission-policy.ts
│   └── config/auth.config.ts
├── docs/auth/EXTENDING.md                    # runbook for future changes
├── CLAUDE.md                                 # appended "Authentication & Authorization" section
└── .env.example                              # JWT_SECRET, JWT_EXPIRATION, JWT_REFRESH_EXPIRATION
```

`app.module.ts` and `main.ts` are patched in place — never overwritten.

---

## Verification

After Phase 5, the skill suggests:

```bash
# Static
npx tsc --noEmit

# Functional
curl -X POST $BASE/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"admin@test.local","password":"Test1234"}'
curl $BASE/auth/me                                         # → 401
curl $BASE/auth/me -H "Authorization: Bearer <token>"      # → 200
```

Throttler check: hit `/auth/login` 6 times with bad creds — the 6th returns `429`.

---

## Iterating on the skill

This skill is meant to be a living artifact. When you find a case the templates don't handle:

1. Edit the relevant template or reference doc.
2. Bump `metadata.version` in `SKILL.md`'s frontmatter.
3. Commit with a descriptive message.

Useful test scenarios:

- **Greenfield**: empty NestJS project → confirm clean scaffold + `tsc` passes
- **Existing auth**: project that already has an `AuthModule` → confirm Phase 1 detects it and Phase 2 asks before writing anything
- **Each ORM**: run once per Mongoose / TypeORM / Prisma / stub variant
- **Single-tenant vs multi-tenant**: confirm `org` claim and `organizationId` are properly conditional

---

## Design philosophy

- **One global guard, not a guard stack.** `@UseGuards(JwtAuthGuard, RolesGuard, PermissionGuard)` on every handler is verbose, slow, and fractures intent. `CompositeAuthGuard` runs once per request and reads decorator metadata.
- **Decorators are the only auth surface.** Handlers state intent with `@Public()`, `@RequirePermission(...)`, `@CurrentUser()`. No middleware wiring per route.
- **Single source of truth.** The `ROLE_PERMISSIONS` matrix in `permission-policy.ts` answers every "can role X do Y?" question. No hard-coded `if (user.role === 'ADMIN')` checks scattered through services.
- **Three permission levels per resource is enough.** Five-level granularity (`READ/CREATE/UPDATE/DELETE/MANAGE`) creates more enum members and matrix entries than it ever pays back. Add `<RESOURCE>_DELETE` ad-hoc only when a specific role needs it split off.
- **Docs that survive turnover.** Future Claude sessions read `docs/auth/EXTENDING.md` instead of re-deriving the architecture from scratch.

---