# Build stage con uv
FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv
WORKDIR /app
ARG RAILWAY_SERVICE_ID
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
COPY uv.lock pyproject.toml /app/
RUN --mount=type=cache,id=s/${RAILWAY_SERVICE_ID}-uv-cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev --no-editable
ADD . /app
RUN --mount=type=cache,id=s/${RAILWAY_SERVICE_ID}-uv-cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Runtime ligero en Alpine
FROM python:3.10-alpine
RUN apk update && apk add --no-cache git
WORKDIR /app
COPY --from=uv /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
ENTRYPOINT ["aci-mcp"]

