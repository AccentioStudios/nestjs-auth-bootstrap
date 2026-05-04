import { SetMetadata } from '@nestjs/common';
import { Permission } from '../../core/authorization/permission-policy{{IMPORT_EXT}}';

export const PERMISSIONS_KEY = 'permissions';
export const RequirePermission = (...permissions: Permission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
export const WithPermissions = RequirePermission;
