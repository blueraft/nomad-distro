# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/engine/reference/builder/

ARG PYTHON_VERSION=3.9

FROM python:${PYTHON_VERSION}-slim as base

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH "${PYTHONPATH}:/backend/"
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

FROM base AS dev

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

ENV RUNTIME docker

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
ADD --chmod=755 https://astral.sh/uv/install.sh /install.sh
RUN /install.sh && rm /install.sh
ENV UV_NO_CACHE=1

COPY packages packages
COPY requirements.txt requirements.txt
COPY pyproject.toml pyproject.toml
# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/uv to speed up subsequent builds.
# Leverage a bind mount to requirements to avoid having to copy them into
# into this layer.
RUN /root/.cargo/bin/uv venv /opt/venv && /root/.cargo/bin/uv pip install -r requirements.txt

# Final stage to create the runnable image with minimal size
FROM python:${PYTHON_VERSION}-slim-bookworm as final

WORKDIR /app

RUN apt-get update \
 && apt-get install --yes --quiet --no-install-recommends \
       libgomp1 \
       libmagic1 \
       curl \
       zip \
       unzip \
 && rm -rf /var/lib/apt/lists/*
 
COPY --from=dev /opt/venv /opt/venv
COPY examples examples

COPY entrypoint.sh .

# Activate the virtualenv in the container
# See here for more information:
# https://pythonspeed.com/articles/multi-stage-docker-python/
ENV PATH="/opt/venv/bin:$PATH"

# Run the application.
ENTRYPOINT ["/app/entrypoint.sh"]
