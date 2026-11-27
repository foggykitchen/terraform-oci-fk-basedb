#!/usr/bin/env bash
# Executed only by the opt-in destroy hook. No credentials are stored here.
set -euo pipefail

if [[ "${CLEANUP_ENABLED:?}" != "true" ]]; then
  exit 0
fi

: "${STANDBY_REGION:?Explicit standby region is required}"
: "${STANDBY_DB_SYSTEM:?Standby DB system OCID is required}"
: "${STANDBY_DATABASE:?Standby database OCID is required}"
: "${PEER_ASSOCIATION:?Standby-side association OCID is required}"
command -v oci >/dev/null || { echo "OCI CLI is required for standby cleanup" >&2; exit 1; }

# All caller values are passed as quoted arguments, never interpolated as shell code.
cli=(oci --region "$STANDBY_REGION")
if [[ -n "${OCI_CLEANUP_PROFILE:-}" ]]; then
  cli+=(--profile "$OCI_CLEANUP_PROFILE")
fi

system_state() {
  "${cli[@]}" db system get --db-system-id "$STANDBY_DB_SYSTEM" \
    --query 'data."lifecycle-state"' --raw-output
}

state=$(system_state)
case "$state" in
  TERMINATED) exit 0 ;;
  TERMINATING) ;; # Resume waiting after an interrupted cleanup.
  AVAILABLE)
    # Do not terminate a peer that has become primary after switchover/failover.
    role=$("${cli[@]}" db data-guard-association get \
      --database-id "$STANDBY_DATABASE" --data-guard-association-id "$PEER_ASSOCIATION" \
      --query 'data.role' --raw-output)
    [[ "$role" == "STANDBY" ]] || { echo "Refusing cleanup: peer role is $role, not STANDBY" >&2; exit 1; }
    # This CLI command waits on a work request, whose success state is SUCCEEDED.
    "${cli[@]}" db system terminate --db-system-id "$STANDBY_DB_SYSTEM" --force \
      --wait-for-state SUCCEEDED --max-wait-seconds 7200
    ;;
  *) echo "Refusing cleanup: unexpected DB system state $state" >&2; exit 1 ;;
esac

# Verify the system lifecycle independently of work-request completion.
# Even a 404 is an error: it can mean missing permissions or a wrong region.
deadline=$((SECONDS + 7200))
while (( SECONDS < deadline )); do
  state=$(system_state)
  case "$state" in
    TERMINATED) exit 0 ;;
    AVAILABLE|TERMINATING) sleep 30 ;;
    *) echo "Standby cleanup failed: unexpected DB system state $state" >&2; exit 1 ;;
  esac
done
echo "Timed out waiting for standby DB system TERMINATED" >&2
exit 1
