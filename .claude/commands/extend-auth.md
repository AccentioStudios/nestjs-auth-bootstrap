---
description: Extend an existing nestjs-auth-bootstrap install — add a new resource, role, permission, or auth recipe.
---

The user wants to extend an auth system previously scaffolded by `nestjs-auth-bootstrap`. Do **not** re-run the full bootstrap.

Steps:

1. **Locate the existing install**:
   - Read `docs/auth/EXTENDING.md` in the target project — it's the runbook for safe extensions.
   - Read `src/core/authorization/permission-policy.ts` for the current `Permission` enum and `ROLE_PERMISSIONS` matrix.
   - Read `src/core/enums.ts` for the current `UserRole` enum.
   - If any of those files are missing, tell the user and stop — they don't have a `nestjs-auth-bootstrap` install. Recommend `/bootstrap-auth` instead.

2. **Identify the extension type** from the user's request:
   - **New resource** (e.g., `INVOICE`) → add `<RESOURCE>_READ`, `<RESOURCE>_WRITE`, `<RESOURCE>_MANAGE` to `Permission`, then map them in `ROLE_PERMISSIONS` for SUPER_ADMIN/ADMIN/USER per the rules in `EXTENDING.md`.
   - **New role** (e.g., `MODERATOR`) → add to `UserRole`, add a row to `ROLE_PERMISSIONS`, update `ASSIGNABLE_ROLES` if relevant.
   - **New recipe** (account lockout, second auth strategy, audit logging) → follow the recipe section in `EXTENDING.md`.
   - **New endpoint protection** → recommend `@RequirePermission(...)` on the handler. Don't stack guards.

3. **Show diff before applying**: print the proposed change to each file, wait for OK, then apply with `Edit`.

4. **Verify**: run `npx tsc --noEmit`. Fix any trivial type errors.

Reference docs in this skill (read-only): `references/permission-model.md`, `references/architecture-overview.md`, `references/adaptation-matrix.md`.

User extension request: $ARGUMENTS
