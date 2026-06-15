# community.saphanasr_resource_agents_angi

[![Shellcheck](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/shellcheck.yml)
[![Mandoc](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/mandoc.yml/badge.svg)](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/mandoc.yml)
[![Perlcritic](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/perlcritic.yml/badge.svg)](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/perlcritic.yml)
[![Pylint](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/pylint.yml/badge.svg)](https://github.com/ja9fuchs/community.saphanasr_resource_agents_angi/actions/workflows/pylint.yml)

Vendor-neutral community source for the SAP HANA System Replication resource agents
(angi generation - unified scale-up and scale-out). Part of the
[sap-linuxlab](https://github.com/sap-linuxlab) project.

## What this is

A community-maintained, vendor-neutral layer tracking
[SUSE/SAPHanaSR](https://github.com/SUSE/SAPHanaSR) (main branch). It applies
minimal transforms on import to remove SUSE-specific naming while keeping all
functional content intact. Distros can pull from here rather than directly from
the SUSE repo.

This is **not a fork**. Feature development and bug fixes belong in the upstream
repo. Contributions that originate here should also be submitted upstream.

## What this is not

- A distro package - no spec files, no packaging integration
- A superset of upstream - HAWK2 wizards and SUSE OBS tooling stay with SUSE

## Repository layout

```
ra/             OCF resource agents and shared libraries
hooks/          HA/DR provider hooks
hooks/samples/  global.ini configuration examples for each hook
alerts/         Pacemaker alert agents
tools/          Cluster monitoring and management utilities
man/            Manual pages
scripts/        Sync tooling (not installed)
```

## Transforms applied on import

| Upstream | Community repo | Reason |
|---|---|---|
| `srHook/susHanaSR.py` | `hooks/HanaSR.py` | strip `sus*` vendor prefix |
| `srHook/susTkOver.py` | `hooks/TkOver.py` | strip `sus*` vendor prefix |
| `srHook/susChkSrv.py` | `hooks/ChkSrv.py` | strip `sus*` vendor prefix |
| `srHook/susCostOpt.py` | `hooks/CostOpt.py` | strip `sus*` vendor prefix |
| `ocf:suse:SAPHana*` | `ocf:heartbeat:SAPHana*` | OCF community provider path |
| `/resource.d/suse/` | `/resource.d/heartbeat/` | OCF community provider path |
| `[ha_dr_provider_susHanaSR]` | `[ha_dr_provider_HanaSR]` | neutral INI section names |

## Installation paths

The resource agents are documented for installation to
`/usr/lib/ocf/resource.d/heartbeat/` (OCF community convention). Distro
packages can override this at packaging time.

## Syncing from upstream

```bash
# Preview changes
./scripts/sync-from-upstream.sh --diff /path/to/SUSE/SAPHanaSR

# Apply
./scripts/sync-from-upstream.sh /path/to/SUSE/SAPHanaSR

# Then: review git diff, update upstream.lock, update CHANGELOG.md
```

## Related

| Scope | Community repo | SUSE upstream |
|---|---|---|
| Angi (unified scale-up/scale-out) | This repo | [SUSE/SAPHanaSR](https://github.com/SUSE/SAPHanaSR) |
| Classic scale-up | [community.saphanasr_resource_agents_scaleup](https://github.com/sap-linuxlab/community.saphanasr_resource_agents_scaleup) | [SUSE/SAPHanaSR (maintenance-classic)](https://github.com/SUSE/SAPHanaSR/tree/maintenance-classic) |
| Classic scale-out | [community.saphanasr_resource_agents_scaleout](https://github.com/sap-linuxlab/community.saphanasr_resource_agents_scaleout) | [SUSE/SAPHanaSR-ScaleOut](https://github.com/SUSE/SAPHanaSR-ScaleOut) |

## License

GPL-2.0 - see [LICENSE](LICENSE). Original work copyright SUSE LLC.
