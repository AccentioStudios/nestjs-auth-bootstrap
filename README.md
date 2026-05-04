# nestjs-auth-bootstrap

Production-grade NestJS authentication & authorization, scaffolded into your project in one guided flow.

A Claude Code plugin that delivers JWT + Passport, OAuth2-style permissions (`READ` / `WRITE` / `MANAGE` per resource), a role matrix, refresh tokens, throttling, and a single global `CompositeAuthGuard` — all driven by decorators (`@Public`, `@RequirePermission`, `@CurrentUser`).

> **Website**: [nestjs-auth-bootstrap.accentiostudios.com](https://nestjs-auth-bootstrap.accentiostudios.com)

---

## What you get

- **AuthModule** — login / refresh / me endpoints, Passport JWT strategy, bcrypt hashing.
- **CompositeAuthGuard** — one global guard handles `@Public` skip, JWT validation, and permission checks. No per-handler `@UseGuards()` stacking.
- **OAuth2-style Permission enum** — `<RESOURCE>_READ`, `<RESOURCE>_WRITE`, `<RESOURCE>_MANAGE` per resource you declare.
- **Role matrix** — `SUPER_ADMIN`, `ADMIN`, `USER` baked in; add custom roles at scaffold time.
- **Refresh tokens** + **`ThrottlerGuard`** + global `ValidationPipe` (`whitelist`, `transform`, `forbidNonWhitelisted`).
- **Persistence variants** — Mongoose, TypeORM, Prisma, or a stub repository you wire later.
- **Living docs** — appends a `CLAUDE.md` auth section and creates `docs/auth/EXTENDING.md` so future agents extend without losing context.

## Installation

### Plugin (recommended)

```bash
/plugin marketplace add accentiostudios/nestjs-auth-bootstrap
/plugin menu
```

Then enable **nestjs-auth-bootstrap** from the plugin menu.

### Manual

```bash
git clone https://github.com/accentiostudios/nestjs-auth-bootstrap.git
cp -r nestjs-auth-bootstrap/.claude/* ~/.claude/
cp -r nestjs-auth-bootstrap/.claude-plugin ~/
```

Restart Claude Code.

## Commands

| Command | Purpose |
|---|---|
| `/bootstrap-auth` | Full 5-phase scaffold: analyze → ask → confirm → execute → verify. |
| `/analyze-auth` | Phase 1 only. Reports project state without writing files. |
| `/extend-auth` | Add a resource, role, or recipe to an existing install via `docs/auth/EXTENDING.md`. |

The skill also auto-triggers on phrases like "add JWT auth", "scaffold authentication", "necesito auth en mi proyecto NestJS", "crea sistema de roles y permisos".

## How it works

The plugin runs a **5-phase blocking workflow**. Each phase requires acknowledgment before the next runs — no file is written before Phase 4.

1. **Analyze** — inspects `package.json`, ORM, folder layout, existing auth artifacts.
2. **Ask** — uses `AskUserQuestion` for adaptive clarification (resources, roles, multi-tenancy).
3. **Confirm** — prints a single block with files, deps, and final enum shapes. Waits for OK.
4. **Execute** — installs deps, renders templates, writes files, merges `app.module.ts` / `main.ts` / `.env.example`.
5. **Verify** — runs `tsc --noEmit`, lists new endpoints, suggests cURL verification.

## Non-negotiable design decisions

These are baked into the templates. Refactor after, not during:

- **One global guard** — `CompositeAuthGuard` via `APP_GUARD`. No guard stacking.
- **Decorator-driven** — `@Public`, `@RequirePermission(...)`, `@CurrentUser()` are the only auth surface in handlers.
- **OAuth2 scope-style permissions** — `WRITE` = create + update + delete. `MANAGE` = admin operations.
- **Single login endpoint** — `POST /auth/login` for all roles. Distinction by permission, not by route.
- **Always included** — refresh tokens, `ThrottlerGuard`, global `ValidationPipe`.
- **Not included by default** — account lockout, secondary auth strategies, audit logging. Recipes live in the generated `EXTENDING.md`.

Full rationale: [`.claude/skills/nestjs-auth-bootstrap/SKILL.md`](./.claude/skills/nestjs-auth-bootstrap/SKILL.md).

## Repository layout

```
.
├── .claude-plugin/
│   ├── marketplace.json       # marketplace entry
│   └── plugin.json            # plugin manifest
├── .claude/
│   ├── commands/              # /bootstrap-auth, /analyze-auth, /extend-auth
│   └── skills/
│       └── nestjs-auth-bootstrap/
│           ├── SKILL.md
│           ├── references/    # architecture, permission model, adaptation matrix
│           └── templates/     # all .tpl files rendered into target project
├── website/                   # static landing page (deploy to Vercel/Pages)
├── .githooks/pre-commit       # auto-versions plugin/marketplace JSON on commit
├── LICENSE
└── README.md
```

## Development

Bump versions automatically on every commit:

```bash
git config core.hooksPath .githooks
```

The hook rewrites `version` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to `YYYY.M.D.HHMM` and re-stages them.

## License

MIT — see [LICENSE](./LICENSE).

---

Built by [Accentio Studios](https://github.com/accentiostudios).
