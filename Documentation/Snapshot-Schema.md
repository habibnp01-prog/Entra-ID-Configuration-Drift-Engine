# Snapshot Schema

A snapshot is a JSON file that captures normalized tenant configuration at a point in time.

## Top-Level Structure

```json
{
  "Version": "0.7.0",
  "TenantId": "1ea32e9d-...",
  "CollectedAtUtc": "2026-10-09T06:30:00.0000000Z",
  "ResourceCount": 110,
  "CollectionSummary": {
    "ConditionalAccessPolicy": 10,
    "DirectoryRole": 15,
    "RoleAssignment": 42,
    "Application": 8,
    "ServicePrincipal": 23,
    "OAuth2PermissionGrant": 12
  },
  "Resources": [ ... ]
}
```

## Resource Shape

Every resource is normalized to a common shape:

```json
{
  "ResourceType": "ConditionalAccessPolicy",
  "ResourceId": "pol-00000001",
  "DisplayName": "Require MFA for all users",
  "Properties": {
    "State": "enabled",
    "Conditions": { ... },
    "GrantControls": { ... }
  }
}
```

## Volatile Properties

The following properties are **excluded** from snapshots so they do not produce false drift:

- `CreatedDateTime`
- `ModifiedDateTime`
- `DeletedDateTime`
- `@odata.context`
- `@odata.type`
- `AdditionalProperties`

## Determinism

- Property names are sorted alphabetically
- Nested objects are compared via canonical JSON serialization
- Resource IDs are the primary key — display names are informational only
