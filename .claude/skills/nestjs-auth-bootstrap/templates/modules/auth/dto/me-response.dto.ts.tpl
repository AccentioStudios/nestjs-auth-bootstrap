export class MeResponseDto {
  id: string;
  name: string;
  email: string;
  role: string;
{{#if MULTI_TENANT}}
  organizationId?: string;
  organizationName?: string;
{{/if}}
}
