import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { UserRole } from '../../../core/enums{{IMPORT_EXT}}';

export type UserDocument = HydratedDocument<User>;

@Schema({ timestamps: true, collection: 'users' })
export class User {
  _id: string;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true, enum: Object.values(UserRole), default: UserRole.USER })
  role: UserRole;

{{#if MULTI_TENANT}}
  @Prop({ type: String, default: null })
  organizationId?: string;
{{/if}}

  @Prop({ type: Date, default: null })
  deletedAt?: Date | null;
}

export const UserSchema = SchemaFactory.createForClass(User);
