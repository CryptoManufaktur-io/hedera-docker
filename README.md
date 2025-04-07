# Overview

Docker Compose for Hedera

## Snapshot Downloading from GCP bucket

You need a service account with `Service Usage Consumer` role to be able to download the snapshot.

Download `serviceaccount.json` file and place it inside `./serviceaccounts` folder then edit the name of the variable `SERVICE_ACCOUNT_FILE` in `.env` to match.

## Use with traefik

Meant to be used with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for traefik
and Prometheus remote write; use `:ext-network.yml` in `COMPOSE_FILE` inside `.env` in that case.

If you want the RPC ports exposed locally, use `hedera-shared.yml` in `COMPOSE_FILE` inside `.env`.

The `./hederad` script can be used as a quick-start:

`./hederad install` brings in docker-ce, if you don't have Docker installed already.

`cp default.env .env`

`nano .env` and adjust variables as needed, particularly mention-important-vars-here

`./hederad up`

To update the software, run `./hederad update` and then `./hederad up`

This is Hedera Docker v1.0.0
