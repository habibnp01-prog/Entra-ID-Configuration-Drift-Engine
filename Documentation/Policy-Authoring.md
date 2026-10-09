# Policy Authoring

Policies are declarative JSON rules that a resource must satisfy.

## Policy File Structure

```json
{
  "version": "1.0.0",
  "policies": [
    {
      "id": "POL-CA-001",
      "name": "All CA policies must have an explicit State",
      "description": "A policy with no State cannot be evaluated.",
      "resourceType": "ConditionalAccessPolicy",
      "property": "State",
      "rule": "MustExist",
      "severity": "High",
      "remediation": "Ensure the policy has a valid State.",
      "references": ["https://learn.microsoft.com/entra/identity/conditional-access/"]
    }
  ]
}
```

## Rules

| Rule | Behavior | Example |
|------|----------|---------|
| `MustExist` | Property must be present | `property: State` |
| `Required` | Property must be present and non-empty | `property: State` |
| `MustBe` | Property must equal a value | `value: enabled` |
| `MustNotBe` | Property must NOT equal a value | `value: disabled` |
| `MustBeOneOf` | Property must be in a list | `value: ["enabled", "reportOnly"]` |
| `MustNotBeOneOf` | Property must NOT be in a list | `value: ["disabled", "unknown"]` |

## Dot-Paths

The `property` field supports dot-notation for nested access:

```json
"property": "Conditions.Users.IncludeUsers"
```

## Exceptions

Exceptions live in `Config/Exceptions.json`:

```json
{
  "exceptions": [
    {
      "policyId": "POL-CA-002",
      "resourceId": "pol-abc",
      "expiresOn": "2027-12-31",
      "owner": "security@example.com",
      "reason": "Approved break-glass policy"
    }
  ]
}
```

- `policyId` is required
- `resourceId` is optional — if `null`, the exception applies to all resources
- `expiresOn` is checked against today's date; expired exceptions are ignored

## Testing

Every policy addition should come with Pester tests using synthetic resources.
