# Verification checklist

Run after Phase 4 completes. The skill should walk the user through these
checks; mark each as ✓ or ✗ in the report.

## 1. Static checks

```bash
npx tsc --noEmit
```

Must pass with zero errors. If errors:

- Path errors with/without `.js` extension → check `tsconfig.json` `module`
  field. ESM-style projects (`module: "Node16"`, `"NodeNext"`, `"ESNext"`)
  require `.js` on relative imports; CJS projects don't.
- Missing decorator metadata → ensure `tsconfig.json` has
  `"emitDecoratorMetadata": true` and `"experimentalDecorators": true`.

## 2. Boot the app

```bash
npm run start:dev
```

Watch the log for:

- `Mapped {/auth/login, POST}` — login route registered
- `Mapped {/auth/refresh, POST}` — refresh route
- `Mapped {/auth/me, GET}` — me route
- No "Nest can't resolve dependencies" errors

## 3. Functional smoke tests

Substitute `<BASE>` with your app's base URL (default `http://localhost:3000`).

### 3a. Login fails on bad credentials

```bash
curl -i -X POST <BASE>/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"none@nowhere.test","password":"wrong"}'
```

Expect `401 Unauthorized`.

### 3b. Login succeeds with seeded user

(Requires a seeded user. If you don't have one, see "Seeding a test user"
below.)

```bash
curl -i -X POST <BASE>/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@test.local","password":"Test1234"}'
```

Expect `200 OK` + body with `accessToken`, `refreshToken`, `expiresIn`.

### 3c. /auth/me without token

```bash
curl -i <BASE>/auth/me
```

Expect `401 Unauthorized`.

### 3d. /auth/me with token

```bash
curl -i <BASE>/auth/me -H "Authorization: Bearer <accessToken>"
```

Expect `200 OK` + body with `id`, `email`, `role`.

### 3e. Permission denied for insufficient role

Create a dummy controller endpoint with
`@RequirePermission(Permission.USER_MANAGE)` and call it as a `USER`-role token.
Expect `403 Forbidden` with message `"Insufficient permissions"`.

### 3f. Refresh token flow

```bash
curl -i -X POST <BASE>/auth/refresh \
  -H 'Content-Type: application/json' \
  -d '{"refreshToken":"<refreshToken from login>"}'
```

Expect `200 OK` + new tokens.

## 4. Throttler check

Hit `/auth/login` 6 times in a minute with bad credentials. The 6th should
return `429 Too Many Requests` (limit is 5/min on login).

## 5. Docs sanity

- `CLAUDE.md` exists and contains the "Authentication & Authorization" section.
- `docs/auth/EXTENDING.md` exists and lists all chosen roles + resources by
  name (not generic placeholders).

## Seeding a test user

If the project has no seed mechanism yet, suggest a quick one-shot script (do
not write it as part of the scaffold unless the user asks):

```ts
// scripts/seed-admin.ts (one-off)
import * as bcrypt from 'bcrypt';
// ...adapt to detected ORM:
//   mongoose: new UserModel({ ... }).save()
//   typeorm:  repo.save({ ... })
//   prisma:   prisma.user.create({ ... })
const passwordHash = await bcrypt.hash('Test1234', 12);
// insert user with role: 'SUPER_ADMIN'
```

## Reporting back to the user

End the verify phase with a short summary like:

```
Verification:
  ✓ tsc --noEmit (0 errors)
  ✓ App boots, 3 routes registered
  ✓ /auth/login rejects bad creds (401)
  ✓ /auth/me rejects no-token (401)
  ✗ Could not run login success test — no seeded user yet
       → Suggest: create a seed user with role SUPER_ADMIN
  Docs:
    ✓ CLAUDE.md updated
    ✓ docs/auth/EXTENDING.md created
```
