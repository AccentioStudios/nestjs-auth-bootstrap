# Merging into `app.module.ts`

The skill must merge these blocks into the project's existing `app.module.ts`.
Do **not** overwrite the file — patch it.

## 1. Add to imports (top of file)

```ts
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { CompositeAuthGuard } from './common/guards/composite-auth.guard{{IMPORT_EXT}}';
import { AuthModule } from './modules/auth/auth.module{{IMPORT_EXT}}';
import authConfig from './config/auth.config{{IMPORT_EXT}}';
```

If `ConfigModule` is not yet imported anywhere, also add the registration to
the `@Module({ imports })` array. If it is already there, just add `authConfig`
to its `load: [...]`.

## 2. Add to `@Module({ imports })`

```ts
ConfigModule.forRoot({
  isGlobal: true,
  load: [authConfig /* + any existing config factories */],
}),
ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
AuthModule,
```

## 3. Add to `@Module({ providers })`

Order matters — ThrottlerGuard runs first, then CompositeAuthGuard:

```ts
{ provide: APP_GUARD, useClass: ThrottlerGuard },
{ provide: APP_GUARD, useClass: CompositeAuthGuard },
```

If `providers` array doesn't exist yet, add it.

## Merging into `main.ts`

Ensure the global `ValidationPipe` is registered. If not present, add inside
the `bootstrap()` function:

```ts
import { ValidationPipe } from '@nestjs/common';

// inside bootstrap(), after `const app = await NestFactory.create(...)`:
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  }),
);
```

If the project already has a `useGlobalPipes(...ValidationPipe...)` call,
verify the options match (or merge). Don't add a second one.
