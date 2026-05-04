// Append this block to your Prisma schema (prisma/schema.prisma).
// Adjust @id strategy and references to match your project.

enum UserRole {
{{USER_ROLE_MEMBERS_PRISMA}}
}

model User {
  id             String    @id @default(uuid())
  name           String
  email          String    @unique
  passwordHash   String
  role           UserRole  @default(USER)
{{#if MULTI_TENANT}}
  organizationId String?
{{/if}}
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt
}
