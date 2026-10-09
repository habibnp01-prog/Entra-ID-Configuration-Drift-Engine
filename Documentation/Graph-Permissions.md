# Graph Permissions

Every collector requires specific Microsoft Graph **application** permissions.

## Permission Matrix

| Collector | Permission | API Endpoint | Notes |
|-----------|-----------|--------------|-------|
| CA Policies | `Policy.Read.All` | `/identity/conditionalAccess/policies` | Read-only |
| Directory Roles | `Directory.Read.All` | `/directoryRoles` | Read-only |
| Role Assignments | `RoleManagement.Read.Directory` | `/roleManagement/directory/roleAssignments` | Read-only |
| Applications | `Application.Read.All` | `/applications` | Read-only |
| Service Principals | `Application.Read.All` | `/servicePrincipals` | Read-only |
| OAuth2 Grants | `Directory.Read.All` | `/oauth2PermissionGrants` | Read-only |
| App Role Assignments | `Application.Read.All` | `/servicePrincipals/{id}/appRoleAssignedTo` | Read-only |

## Least Privilege

Do **not** grant write permissions. This engine is a reader by design.

If you later enable remediation, add only the specific write scopes required for the specific action.

## Consent

All listed permissions require **admin consent** in the target tenant.

## Rate Limits

Microsoft Graph applies per-tenant and per-app throttling. The engine uses:

- `-All` for pagination
- Retries with backoff when the SDK signals throttling
- Read-only calls, which are less likely to hit aggressive limits
