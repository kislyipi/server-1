FROM prom/prometheus:v3.13.0
USER root
RUN apt-get update && apt-get install -y gettext && rm -rf /var/lib/apt/lists/*
USER nobody