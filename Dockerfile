# Etapa de build usando uv (astral‑sh)
FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv

WORKDIR /app

# Habilitamos compilación de bytecode y modo de link
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Instalamos las dependencias según uv.lock + pyproject.toml
COPY uv.lock pyproject.toml /app/
RUN uv sync --frozen --no-install-project --no-dev --no-editable

# Añadimos el código fuente y volvemos a sync para incluir el proyecto
ADD . /app
RUN uv sync --frozen --no-dev --no-editable

# Etapa final: pequeña imagen de Python
FROM python:3.10-slim-bookworm

# Instalamos git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiamos entorno virtual y binarios de uv
COPY --from=uv /root/.local /root/.local
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Colocamos los ejecutables al frente del PATH
ENV PATH="/app/.venv/bin:$PATH"

# Comando por defecto
ENTRYPOINT ["aci-mcp"]
