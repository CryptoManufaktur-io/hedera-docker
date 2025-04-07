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

gcloud_login() {
    gcloud auth activate-service-account --key-file=/serviceaccounts/"$SERVICE_ACCOUNT_FILE"
    gcloud storage ls gs://mirrornode-db-export/ --billing-project="$PROJECT_ID"
}

# ---------- Download snapshot files from GCP ---------------------------
if [ ! -f "/data/snapshot_downloaded" ]; then
    echo "Downloading Minimal DB Data Files from GCP"
    gcloud_login

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

# ---------- Redownload discrepancies files ---------------------------
if [ -f "/data/bootstrap_discrepancies.log" ]; then
    echo "Redownloading Files from GCP that have discrepancies"
    BUCKET_PATH="gs://mirrornode-db-export/$SNAPSHOT_VERSION"
    LOCAL_BASE="/data/download"

    while IFS= read -r line; do
        # Extract path by stripping before the colon
        local_path="${line%%:*}"

        # Remove /data/download/ prefix
        relative_path="${local_path#"$LOCAL_BASE/"}"

        # Construct the remote path
        remote_path="$BUCKET_PATH/$relative_path"

        echo "Re-downloading $relative_path ..."

        # Download the file
        gcloud storage cp "$remote_path" "$local_path"
    done < /data/bootstrap_discrepancies.log

    rm -f /data/bootstrap_discrepancies.log
    echo "Done redownloading Files from GCP that have discrepancies"
fi
# ---------- Redownload discrepancies files ---------------------------


tail_log() {
    tail -f "$BG_LOG_FILE"
}

BG_LOG_FILE="/data/bootstrap.log"
if [ -f "$BG_LOG_FILE" ] && grep -q "DB import completed successfully" "$BG_LOG_FILE"; then
    echo "Done running bootstrap script"
    exit 0
else
    # Start tailing the log in the background
    tail_log &
    tail_pid=$!

    echo "Running bootstrap script (tail PID: $tail_pid) ..."
    echo "" >> "$BG_LOG_FILE"
    ./bootstrap.sh "$SNAPSHOT_CPU_CORES" /data/download > /dev/null 2>> bootstrap.log
fi
