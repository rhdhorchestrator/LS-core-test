FROM python:3.13-slim

# Install system dependencies including Java and Maven
RUN apt-get update && apt-get install -y \
    curl \
    openjdk-21-jdk \
    maven \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen

COPY serverless-workflow serverless-workflow
WORKDIR serverless-workflow

RUN mvn clean package
RUN mkdir -p /app/kogito && \
    cp target/my-workflow-project-1.0-SNAPSHOT.jar /app/kogito/app.jar && \
    cp target/dependency/* /app/kogito/ 2>/dev/null || true

WORKDIR /app

# Copy application code
COPY mcp_server.py ./
COPY tools/ ./tools/

# Expose port
EXPOSE 8000

# Run the application
CMD ["uv", "run", "python", "mcp_server.py"]
