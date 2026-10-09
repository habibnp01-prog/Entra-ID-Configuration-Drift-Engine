# Remediation Safety

The engine defaults to **read-only**. No tenant change happens without explicit consent.

## Safety Gates

1. **`-Mode Plan`** — generates a plan file only, no Graph calls beyond reads
2. **`-Apply` switch** — required to execute any auto-remediable action
3. **`SupportsShouldProcess`** — native `-WhatIf` and `-Confirm` support
4. **Post-change verification** — every applied change is re-read from Graph
5. **Manual-only by default** — most resource types require human action

## What Is Auto-Remediable

Only **Conditional Access policy state** changes (enabled/disabled) are auto-remediable in this version.

Everything else is **recommendation-only**:

- Application permission changes
- Role assignment changes
- Service principal configuration
- OAuth2 grant changes

## Never Automatically

- Deleted or restored resources
- Added or removed privileged assignments
- Revoked permissions or consent grants
- Disabled or deleted CA policies

## Verification

After `Update-MgIdentityConditionalAccessPolicy`, the engine re-reads the policy and checks the actual State value.

If it does not match the desired value, the action is marked performed but not verified, with the discrepancy logged.

## Rollback

Rollback is not automated. Because every change is a simple CA policy State flip, manual rollback is straightforward: flip the State back via the Entra admin center or a re-run of `-Mode Plan` after baseline update.
