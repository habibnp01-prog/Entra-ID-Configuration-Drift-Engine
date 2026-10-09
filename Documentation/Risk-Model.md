# Risk Model

Severity is assigned to findings according to the rules below.

## Severity Levels

| Level | Meaning |
|-------|---------|
| Critical | Immediate security impact. Removed resources, disabled enforced policies, unexpected privileged assignments. |
| High | Significant risk. New privileged capabilities, missing required controls on sensitive resources. |
| Medium | Moderate risk. Modified non-critical properties, policy violations on less-sensitive resources. |
| Low | Minor risk or informational drift. |

## Drift Severity

| Category | Default Severity |
|----------|------------------|
| Removed | Critical |
| Added | High |
| Modified (Removed property) | High |
| Modified (Added property) | Medium |
| Modified (Changed value) | Medium |

## Policy Severity

Each policy definition carries its own `severity` field. This is not inferred automatically — you set it when you write the policy.

## Overriding

Severity can be overridden per finding via `Config/Exceptions.json` (future enhancement).
