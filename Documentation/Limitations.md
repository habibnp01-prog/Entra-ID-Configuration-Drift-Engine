# Limitations

Honest list of what this engine does **not** do.

## Not Implemented

- **Change attribution.** Snapshots do not prove who made a change. The engine cannot attribute drift to an actor without audit log correlation.
- **Automatic remediation of non-CA resources.** Only CA policy State flips are auto-remediable.
- **Real-time monitoring.** All operations are pull-based and on-demand.
- **Multi-tenant.** One engine instance targets one tenant.
- **Cloud PKI integration.** Certificates must be managed externally.

## Supported So Far

- Conditional Access policies
- Directory roles
- Role assignments
- Applications
- Service principals
- OAuth2 permission grants
- App role assignments

## Not Yet Collected

- Authentication methods policies
- Named locations
- Terms of use / consent policies
- Identity Protection risk policies
- Cross-tenant access settings
- Workload identity federation configs

Each of these would require its own collector and would need to be added to `Invoke-ModeCollect`.

## Performance Notes

A full collection against a large tenant (100k+ users) may take several minutes. Pagination is automatic but the total call count grows with tenant size.

## Known Gaps

- Policy engine does not yet support nested array comparisons (e.g., "any user in group X")
- Remediation plan for `MustExist` rule does not suggest a default value
- HTML report does not yet group findings by category for large result sets
