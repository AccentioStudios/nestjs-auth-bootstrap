---
description: Analyze the current NestJS project for auth readiness (Phase 1 only — no file writes).
---

Run **Phase 1 (Analyze) only** of the `nestjs-auth-bootstrap` skill. Do not write or modify any files.

Inspect the target project and report a markdown table with:

| Aspect | Finding |
|---|---|
| NestJS version | from `package.json` → `@nestjs/core` |
| Package manager | npm / pnpm / yarn (detect from lockfile) |
| ORM | mongoose / typeorm / prisma / none |
| Existing auth artifacts | `AuthModule`, `JwtStrategy`, `JwtAuthGuard`, `permission-policy`, `@Public()`, `@RequirePermission` — list paths |
| Folder layout | `src/modules/`, `src/common/`, `src/core/`, or other |
| `app.module.ts` location | path + where `AuthModule` should merge |
| Global `ValidationPipe` | yes/no in `main.ts` |
| `.env.example` JWT keys | list any `JWT_*` already present |
| Conflicts / risks | anything blocking a clean scaffold |

Close with a one-paragraph recommendation: clean install, merge with existing, or abort. Do NOT proceed to Phase 2 unless user runs `/bootstrap-auth` next.

User input (optional, project hints): $ARGUMENTS
