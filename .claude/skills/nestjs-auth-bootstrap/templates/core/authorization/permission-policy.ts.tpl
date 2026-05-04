import { UserRole } from '../enums{{IMPORT_EXT}}';

// ─────────────────────────────────────────────────────────────
// PERMISSION ENUM — OAuth2 scope style: <RESOURCE>_<LEVEL>
// READ   = list, get-one, view
// WRITE  = create, update, delete on the resource itself
// MANAGE = admin ops about the resource (assign roles, lock, audit)
// To add a resource: add three lines here, then update ROLE_PERMISSIONS.
// ─────────────────────────────────────────────────────────────
export enum Permission {
{{PERMISSION_MEMBERS}}
}

// ─────────────────────────────────────────────────────────────
// ROLE → PERMISSIONS TABLE
// Single source of truth for authorization. Audit this to see
// exactly what each role can do.
// ─────────────────────────────────────────────────────────────
export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
{{ROLE_PERMISSIONS_BODY}}
};

// ─────────────────────────────────────────────────────────────
// ROLE → ASSIGNABLE ROLES TABLE
// Controls privilege escalation: which roles each role may assign
// when creating or updating users. SUPER_ADMIN can assign itself;
// nobody else can.
// ─────────────────────────────────────────────────────────────
export const ASSIGNABLE_ROLES: Record<UserRole, UserRole[]> = {
{{ASSIGNABLE_ROLES_BODY}}
};

export function hasPermission(role: UserRole, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role]?.includes(permission) ?? false;
}

export function canAssignRole(
  actorRole: UserRole,
  targetRole: UserRole,
): boolean {
  return ASSIGNABLE_ROLES[actorRole]?.includes(targetRole) ?? false;
}

export function getAssignableRoles(role: UserRole): UserRole[] {
  return ASSIGNABLE_ROLES[role] ?? [];
}
