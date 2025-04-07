#!/usr/bin/env bash
set -euo pipefail
cd /data

if [[ -n "$SKIP_SNAPSHOT_INIT" && "$SKIP_SNAPSHOT_INIT" == "true" ]]; then
    echo "Skipping initialization due to SKIP_SNAPSHOT_INIT=true"
    exit 0
else
    echo "Performing initialization since SKIP_SNAPSHOT_INIT=false"
fi

if [ -z "$SNAPSHOT_VERSION" ]; then
    echo "Error: SNAPSHOT_VERSION is not set or is empty."
    exit 1
fi
if [ -z "$ACCESS_KEY" ]; then
    echo "Error: ACCESS_KEY is not set or is empty."
    exit 1
fi
if [ -z "$SECRET_KEY" ]; then
    echo "Error: SECRET_KEY is not set or is empty."
    exit 1
fi
if [ -z "$PROJECT_ID" ]; then
    echo "Only GCP is supported and PROJECT_ID is empty"
    exit 1
fi

# ---------- Download snapshot files from GCP ---------------------------
if [ ! -f "/data/snapshot_downloaded" ]; then
    echo "Downloading Minimal DB Data Files from GCP"

    gcloud auth activate-service-account --key-file=/serviceaccounts/"$SERVICE_ACCOUNT_FILE"
    gcloud storage ls gs://mirrornode-db-export/ --billing-project="$PROJECT_ID"

    mkdir -p /data/download
    export CLOUDSDK_STORAGE_SLICED_OBJECT_DOWNLOAD_MAX_COMPONENTS=1
    export VERSION_NUMBER=$SNAPSHOT_VERSION

    gcloud storage rsync --billing-project="$PROJECT_ID" -r -x '.*_part_\d+_\d+_\d+_atma\.csv\.gz$' "gs://mirrornode-db-export/$VERSION_NUMBER/" /data/download

    echo "Done downloading files" >> /data/snapshot_downloaded

    echo "Done downloading minimal DB Data Files"
else
    echo "Snapshot files already downloaded"
fi
# ---------- Download snapshot files from GCP ---------------------------


BG_LOG_FILE="/data/bootstrap.log"
if [ ! -f "$BG_LOG_FILE" ]; then
    echo "" >> "$BG_LOG_FILE"
fi

tail_log() {
    tail -f "$BG_LOG_FILE"
}

# Start tailing the log in the background
tail_log &
tail_pid=$!

echo "Running bootstrap script (tail PID: $tail_pid) ..."

set +e
(
  ./bootstrap.sh "$SNAPSHOT_CPU_CORES" /data/download > /dev/null 2>> bootstrap.log
)
exit_code=$?
set -e

kill "$tail_pid"
wait "$tail_pid"

if [ "$exit_code" -eq 0 ]; then
    echo "Done running bootstrap script"
    exit 0
else
    echo "Bootstrap script import process failed."
    exit 1
fi
