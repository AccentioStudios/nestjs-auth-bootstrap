---
description: Scaffold full NestJS auth system (JWT + Passport + permissions + refresh tokens + throttling) via guided 5-phase flow.
---

Run the `nestjs-auth-bootstrap` skill end-to-end on the current NestJS project.

Execute all 5 phases defined in `.claude/skills/nestjs-auth-bootstrap/SKILL.md`:

1. **Analyze** — inspect `package.json`, ORM, folder layout, existing auth artifacts. Report findings as a markdown table. Do NOT edit files yet.
2. **Ask** — use `AskUserQuestion` to fill gaps: existing-auth handling, ORM choice if missing, extra resources for the Permission enum, extra roles, multi-tenancy, target paths.
3. **Confirm** — print a single block listing files to create/modify, dependencies to install, and the final shape of `Permission` + `ROLE_PERMISSIONS` + `UserRole`. Wait for explicit OK.
4. **Execute** — install deps with detected package manager, render templates from `templates/`, write files, merge `app.module.ts` + `main.ts` + `.env.example`, append `CLAUDE.md` auth section, create `docs/auth/EXTENDING.md`.
5. **Verify** — run `npx tsc --noEmit` (or `npm run build`), report errors verbatim, list new endpoints (`POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`), suggest verification cURL commands from `references/verification-checklist.md`.

Block each phase until the prior is acknowledged. Never improvise mid-scaffold — if the user wants to deviate from the non-negotiable design decisions in `SKILL.md`, complete the run first and refactor after.

User input (optional, may include constraints, ORM preference, extra roles): $ARGUMENTS
