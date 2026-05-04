import { Injectable } from '@nestjs/common';
import { UserRole } from '../../core/enums{{IMPORT_EXT}}';

export interface UserEntity {
  id: string;
  name: string;
  email: string;
  passwordHash: string;
  role: UserRole;
{{#if MULTI_TENANT}}
  organizationId?: string;
{{/if}}
}

/**
 * Stub repository. Replace the in-memory store with your real persistence
 * layer. The skill scaffolds against this interface so you can wire any
 * datastore later without changing AuthService.
 */
@Injectable()
export class UserRepository {
  private readonly users = new Map<string, UserEntity>();

  async findById(id: string): Promise<UserEntity | null> {
    return this.users.get(id) ?? null;
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    for (const user of this.users.values()) {
      if (user.email === email) return user;
    }
    return null;
  }

  async create(user: UserEntity): Promise<UserEntity> {
    this.users.set(user.id, user);
    return user;
  }
}
