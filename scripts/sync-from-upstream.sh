#!/bin/bash
# Syncs files from a local clone of SUSE/SAPHanaSR (main branch) and applies
# vendor-neutral transforms on import.
#
# Usage: ./scripts/sync-from-upstream.sh [--dry-run | --diff] /path/to/SAPHanaSR
#
# After running:
#   1. Review `git diff` - do not commit blindly
#   2. Update upstream.lock with the upstream commit SHA:
#        git -C /path/to/SAPHanaSR rev-parse HEAD
#   3. Update CHANGELOG.md

set -euo pipefail

DRY_RUN=0
SHOW_DIFF=0
UPSTREAM=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] /path/to/SAPHanaSR

Sync files from a local clone of SUSE/SAPHanaSR and apply vendor-neutral
transforms on import.

Options:
  -n, --dry-run   Show what would be synced without writing any files
      --diff      Like --dry-run but also show file diffs
  -h, --help      Show this help and exit

After running:
  1. Review:     git diff
  2. Lock:       git -C /path/to/SAPHanaSR rev-parse HEAD  -> update upstream.lock
  3. Changelog:  update CHANGELOG.md
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --diff)       DRY_RUN=1; SHOW_DIFF=1 ;;
        --help|-h)    usage; exit 0 ;;
        -*) echo "Unknown option: $arg" >&2; exit 1 ;;
        *) UPSTREAM="$arg" ;;
    esac
done

if [ -z "$UPSTREAM" ]; then
    usage >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if [ ! -d "$UPSTREAM/.git" ]; then
    echo "ERROR: $UPSTREAM does not look like a git repo" >&2
    exit 1
fi

if [ "$SHOW_DIFF" -eq 1 ]; then
    echo "(dry run with diff - no files will be written)"
elif [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry run - no files will be written)"
fi

log_sync() {
    printf "  %-8s %-36s ->  %s\n" "$1" "$2" "$3"
}

log_neutral() {
    printf "  %-8s %-36s     (%s -> %s)\n" "neutral" "$1" "$2" "$3"
}

sync_file() {
    local src="$UPSTREAM/$1"
    local dst="$REPO_ROOT/$2"

    if [ ! -f "$src" ]; then
        printf "  %-8s upstream file not found: %s\n" "WARNING" "$1" >&2
        return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        if [ ! -f "$dst" ]; then
            log_sync "new" "$1" "$2"
            if [ "$SHOW_DIFF" -eq 1 ]; then
                diff -u /dev/null "$src" | tail -n +3 | sed 's/^/    /' || true
            fi
        elif diff -q "$src" "$dst" > /dev/null 2>&1; then
            log_sync "same" "$1" "$2"
        else
            log_sync "changed" "$1" "$2"
            if [ "$SHOW_DIFF" -eq 1 ]; then
                diff -u "$dst" "$src" | tail -n +3 | sed 's/^/    /' || true
            fi
        fi
    else
        install -D -m 644 "$src" "$dst"
        log_sync "synced" "$1" "$2"
    fi
}

# neutralize_sus replaces sus* symbols in a synced hook file.
# Does NOT touch: copyright lines, provider_company, or other SUSE references.
neutralize_sus() {
    local dst_rel="$1" sus="$2" neutral="$3"
    local file="$REPO_ROOT/$dst_rel"
    local sus_lo neutral_lo
    sus_lo=$(printf '%s' "$sus" | tr '[:upper:]' '[:lower:]')
    neutral_lo=$(printf '%s' "$neutral" | tr '[:upper:]' '[:lower:]')

    if [ "$DRY_RUN" -eq 1 ]; then
        log_neutral "$dst_rel" "$sus" "$neutral"
        return
    fi

    sed -i \
        -e "s/^# ${sus}\\.py\$/# ${neutral}.py/" \
        -e "s/^${sus}\$/${neutral}/" \
        -e "s/^${sus} needs /${neutral} needs /" \
        -e "s/\\[ha_dr_provider_${sus}\\]/[ha_dr_provider_${neutral}]/g" \
        -e "s/\\[ha_dr_provider_${sus_lo}\\]/[ha_dr_provider_${neutral_lo}]/g" \
        -e "/provider = ${sus}\$/s/${sus}/${neutral}/" \
        -e "s/ha_dr_${sus_lo}[[:space:]]/ha_dr_${neutral_lo} /g" \
        -e "s/^SRHookName = \"${sus}\"\$/SRHookName = \"${neutral}\"/" \
        -e "s/class ${sus}(HADRBase)/class ${neutral}(HADRBase)/" \
        -e "s/\"\"\" class ${sus} /\"\"\" class ${neutral} /" \
        -e "s/nameserver_${sus_lo}\\.trc/nameserver_${neutral_lo}.trc/g" \
        -e "s/\"provider_name\": \"${sus}\"/\"provider_name\": \"${neutral}\"/" \
        -e "s/f\"${sus} /f\"${neutral} /g" \
        -e "s/${sus_lo}_timeout/${neutral_lo}_timeout/g" \
        "$file"
    log_neutral "$dst_rel" "$sus" "$neutral"
}


echo ""
echo "==> Resource agents"
sync_file ra/SAPHanaController             ra/SAPHanaController
sync_file ra/SAPHanaFilesystem             ra/SAPHanaFilesystem
sync_file ra/SAPHanaTopology               ra/SAPHanaTopology
sync_file ra/saphana-common-lib            ra/saphana-common-lib
sync_file ra/saphana-controller-common-lib ra/saphana-controller-common-lib
sync_file ra/saphana-controller-lib        ra/saphana-controller-lib
sync_file ra/saphana-filesystem-lib        ra/saphana-filesystem-lib
sync_file ra/saphana-topology-lib          ra/saphana-topology-lib

echo ""
echo "==> Hooks"
sync_file srHook/susChkSrv.py              hooks/ChkSrv.py
sync_file srHook/global.ini_susChkSrv      hooks/samples/global.ini_ChkSrv
sync_file srHook/susCostOpt.py             hooks/CostOpt.py
sync_file srHook/global.ini_susCostOpt     hooks/samples/global.ini_CostOpt
sync_file srHook/susHanaSR.py              hooks/HanaSR.py
sync_file srHook/global.ini_susHanaSR      hooks/samples/global.ini_HanaSR
sync_file srHook/susTkOver.py              hooks/TkOver.py
sync_file srHook/global.ini_susTkOver      hooks/samples/global.ini_TkOver

echo ""
echo "==> Alerts"
sync_file alert/SAPHanaSR-alert-fencing    alerts/SAPHanaSR-alert-fencing

echo ""
echo "==> Tools"
sync_file tools/SAPHanaSR-cibBrush         tools/SAPHanaSR-cibBrush
sync_file tools/SAPHanaSR-hookHelper       tools/SAPHanaSR-hookHelper
sync_file tools/SAPHanaSR-manageProvider   tools/SAPHanaSR-manageProvider
sync_file tools/SAPHanaSR-replay-archive   tools/SAPHanaSR-replay-archive
sync_file tools/SAPHanaSR-showAttr         tools/SAPHanaSR-showAttr
sync_file tools/SAPHanaSR-showStatus       tools/SAPHanaSR-showStatus
sync_file tools/SAPHanaSRTools.pm          tools/SAPHanaSRTools.pm
sync_file tools/saphana_sr_tools.py        tools/saphana_sr_tools.py
sync_file tools/properties.json            tools/properties.json
sync_file py/SAPHanaSR.py                  tools/SAPHanaSR.py

# man/ is NOT synced from upstream.
# The three RA parameter pages (ocf_heartbeat_SAPHana{Controller,Filesystem,Topology}.7)
# are auto-generated from RA metadata via the ClusterLabs resource-agents toolchain and
# committed as static files.  Update them manually when RA parameters change significantly.

echo ""
echo "==> Linter configs"
sync_file .pylintrc     .pylintrc
sync_file .perlcriticrc .perlcriticrc
sync_file .perltidyrc   .perltidyrc

echo ""
echo "==> Neutralization  (sus* symbols replaced; OCF provider path updated)"
if [ "$DRY_RUN" -eq 0 ]; then
    sed -i 's/\.suse_SAPHanaFilesystem/\.SAPHanaFilesystem/g' \
        "$REPO_ROOT/ra/saphana-filesystem-lib"
fi
log_neutral "ra/saphana-filesystem-lib" ".suse_SAPHanaFilesystem" ".SAPHanaFilesystem"
neutralize_sus hooks/ChkSrv.py                  susChkSrv  ChkSrv
neutralize_sus hooks/samples/global.ini_ChkSrv  susChkSrv  ChkSrv
neutralize_sus hooks/CostOpt.py                 susCostOpt CostOpt
neutralize_sus hooks/samples/global.ini_CostOpt susCostOpt CostOpt
neutralize_sus hooks/HanaSR.py                  susHanaSR  HanaSR
neutralize_sus hooks/samples/global.ini_HanaSR  susHanaSR  HanaSR
neutralize_sus hooks/TkOver.py                  susTkOver  TkOver
neutralize_sus hooks/samples/global.ini_TkOver  susTkOver  TkOver

# Excluded from upstream - not pulled, documented here for clarity:
#
#   wizard/                     HAWK2 web UI wizards - SUSE-specific
#   icons/                      SAPHanaSR-monitor SVG icons - SUSE-specific
#   *.spec / *.changes          RPM packaging - distro repos handle this
#   00_files_to_osc             SUSE OBS deployment script
#   Makefile (OBS targets)      community Makefile is maintained separately
#   srHook/susHanaSrMultiTarget.py  WIP / not yet integrated upstream
#   SAPHanaSR-upgrade-to-angi-demo  SUSE-specific migration utility
#   man/SAPHanaSR-upgrade-to-angi-demo.8  doc for above
#
# Not yet synced - planned for later:
#   crm_cfg/angi-ScaleUp/   -> crm_cfg/crmsh/   used as test automation input; needs ocf:suse: -> ocf:heartbeat: fix
#   test/                                        test framework; crm_cfg dependency must be resolved first

echo ""
echo "Done."
echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Next step:"
    echo "  Run without --dry-run to apply changes"
else
    echo "Next steps:"
    echo "  1. Review:     git diff"
    echo "  2. Lock:       git -C $UPSTREAM rev-parse HEAD  -> update upstream.lock"
    echo "  3. Changelog:  update CHANGELOG.md"
fi
