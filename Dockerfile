FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv
WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

COPY uv.lock pyproject.toml /app/
RUN uv sync --frozen --no-install-project --no-dev --no-editable

ADD . /app
RUN uv sync --frozen --no-dev --no-editable

FROM python:3.10-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=uv /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
ENTRYPOINT ["aci-mcp"]
