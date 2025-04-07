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

    gcloud auth activate-service-account --key-file=/serviceaccounts/$SERVICE_ACCOUNT_FILE
    gcloud storage ls gs://mirrornode-db-export/ --billing-project=$PROJECT_ID

    mkdir -p /data/download
    export CLOUDSDK_STORAGE_SLICED_OBJECT_DOWNLOAD_MAX_COMPONENTS=1
    export VERSION_NUMBER=$SNAPSHOT_VERSION

    gcloud storage rsync --billing-project=$PROJECT_ID -r -x '.*_part_\d+_\d+_\d+_atma\.csv\.gz$' "gs://mirrornode-db-export/$VERSION_NUMBER/" /data/download

    echo "Done downloading files" >> /data/snapshot_downloaded

    echo "Done downloading minimal DB Data Files"
else
    echo "Snapshot files already downloaded"
fi
# ---------- Download snapshot files from GCP ---------------------------

# run bootstrap.log
./bootstrap.sh $SNAPSHOT_CPU_CORES /data/download > /dev/null 2>> bootstrap.log

echo "Done running bootstrap script"
exit 1
