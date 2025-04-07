FROM python:3.12-slim-bullseye

# Define mounted volume
VOLUME /data

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY bootstrap.sh /data/bootstrap.sh
COPY bootstrap.env /data/bootstrap.env

RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y postgresql-client curl apt-transport-https ca-certificates gnupg nano && python3 -m pip install rapidgzip  \
        && rm -rf /var/lib/apt/lists/*

# Install b3sum
RUN curl -L https://github.com/BLAKE3-team/BLAKE3/releases/download/1.8.0/b3sum_linux_x64_bin -o /usr/local/bin/b3sum && chmod +x /usr/local/bin/b3sum

# Install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && apt-get update -y && apt-get install google-cloud-cli -y

ENTRYPOINT [ "docker-entrypoint.sh" ]
