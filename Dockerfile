ARG RAILWAY_CACHE_KEY  # ¡Nueva línea crítica!

FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv
WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Cache con prefijo dinámico
RUN --mount=type=cache,id=${RAILWAY_CACHE_KEY}uv-pip,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

ADD . /app

# Mismo ID de caché con prefijo
RUN --mount=type=cache,id=${RAILWAY_CACHE_KEY}uv-pip,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

FROM python:3.10-slim-bookworm
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=uv --chown=app:app /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
RUN groupadd -r app && useradd -r -g app app && chown -R app:app /app
USER app
ENTRYPOINT ["aci-mcp"]
