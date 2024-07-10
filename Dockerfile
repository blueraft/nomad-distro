# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/engine/reference/builder/

ARG PYTHON_VERSION=3.9

FROM python:${PYTHON_VERSION}-slim AS base

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

FROM base AS builder

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

ENV RUNTIME=docker

WORKDIR /app

# Create a non-privileged user that the frenrug will run under.
# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    nomad

RUN apt-get update \
 && apt-get install --yes --quiet --no-install-recommends \
      libgomp1 \
      libmagic1 \
      file \
      gcc \
      build-essential \
      curl \
      zip \
      unzip \
      git \
 && rm -rf /var/lib/apt/lists/*

# Install UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin/:$PATH"

ENV UV_NO_CACHE=1

COPY packages packages
COPY requirements.txt requirements.txt
COPY pyproject.toml pyproject.toml
# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/uv to speed up subsequent builds.
# Leverage a bind mount to requirements to avoid having to copy them into
# into this layer.
RUN uv venv /opt/venv && uv pip install -r requirements.txt

COPY examples ./examples
COPY scripts ./scripts

RUN ./scripts/generate_example_uploads.sh

# Final stage to create the runnable image with minimal size
FROM python:${PYTHON_VERSION}-slim-bookworm AS final

WORKDIR /app

RUN apt-get update \
 && apt-get install --yes --quiet --no-install-recommends \
       libgomp1 \
       libmagic1 \
       curl \
       zip \
       unzip \
       nodejs \
       npm \
       && npm install -g configurable-http-proxy@^4.2.0 \
       # clean cache and logs
       && rm -rf /var/lib/apt/lists/* /var/log/* /var/tmp/* ~/.npm
 
COPY --from=builder /opt/venv /opt/venv

# Activate the virtualenv in the container
# See here for more information:
# https://pythonspeed.com/articles/multi-stage-docker-python/
ENV PATH="/opt/venv/bin:$PATH"

RUN useradd -u 1000 nomad

COPY --chown=nomad:1000 --from=builder /app/examples/data/uploads /app/examples/data/uploads
COPY --chown=nomad:1000 scripts/run.sh .
COPY --chown=nomad:1000 scripts/run-worker.sh .

RUN mkdir -p /app/.volumes/fs \
 && chown -R nomad:1000 /app \
 && chown -R nomad:1000 /opt/venv

USER nomad

# The application ports
EXPOSE 8000
EXPOSE 9000

VOLUME /app/.volumes/fs
