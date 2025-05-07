# Etapa de build usando uv (astral-sh)
FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim AS uv

WORKDIR /app

# 1) Declaramos el ARG que Railway inyecta con el service ID  
#    (necesario para el id= de los cache mounts)  
ARG RAILWAY_SERVICE_ID

# Habilitamos compilación de bytecode y modo de link
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# 2) Instalamos dependencias con uv.lock + pyproject.toml,
#    usando cache mount con id prefijado: s/${RAILWAY_SERVICE_ID}-uv-cache
RUN --mount=type=cache,id=s/${RAILWAY_SERVICE_ID}-uv-cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Copiamos el resto del código y volvemos a sync para incluir el proyecto
ADD . /app
RUN --mount=type=cache,id=s/${RAILWAY_SERVICE_ID}-uv-cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Etapa final: pequeña imagen de Python
FROM python:3.10-slim-bookworm

# Instalamos git (u otros paquetes que necesites)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiamos el entorno virtual y los binarios de uv
COPY --from=uv /root/.local /root/.local
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Ponemos los ejecutables al frente del PATH
ENV PATH="/app/.venv/bin:$PATH"

# Comando por defecto
ENTRYPOINT ["aci-mcp"]
