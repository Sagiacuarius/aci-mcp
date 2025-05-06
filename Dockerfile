# Etapa UV para instalación de dependencias
FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv

WORKDIR /app

# Configuraciones de UV
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Instalar dependencias principales (AÑADIDO id=uv-cache)
RUN --mount=type=cache,id=uv-cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Copiar código fuente e instalar la aplicación (MISMO ID DE CACHÉ)
ADD . /app
RUN --mount=type=cache,id=uv-cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Etapa final
FROM python:3.10-slim-bookworm

# Instalar git (necesario para MCP)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar entorno virtual
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Configurar PATH y permisos
ENV PATH="/app/.venv/bin:$PATH"
RUN groupadd -r app && \
    useradd -r -g app app && \
    chown -R app:app /app && \
    chmod -R 755 /app

# Usuario no root
USER app

# Entrypoint
ENTRYPOINT ["aci-mcp"]
