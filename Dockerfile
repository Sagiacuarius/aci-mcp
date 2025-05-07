# Define el ARG al inicio
ARG RAILWAY_CACHE_KEY

FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Es necesario redeclarar el ARG después de cada FROM
ARG RAILWAY_CACHE_KEY

# Cache con prefijo explícito
RUN --mount=type=cache,id=uv-pip-${RAILWAY_CACHE_KEY},target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

ADD . /app

# Mismo formato de ID de caché
RUN --mount=type=cache,id=uv-pip-${RAILWAY_CACHE_KEY},target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

FROM python:3.10-slim-bookworm
WORKDIR /app
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
COPY --from=uv --chown=app:app /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
RUN groupadd -r app && useradd -r -g app app && chown -R app:app /app
USER app
ENTRYPOINT ["aci-mcp"]
