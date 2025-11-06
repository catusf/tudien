# For more information, please refer to https://aka.ms/vscode-docker-python
#FROM python:3-slim
FROM python:3

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    pkg-config \
    curl \
    liblzo2-2 liblzo2-dev \ 
    libmariadb-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# WORKDIR /workspaces/tudien

# RUN ./bin/install_linux_packages.sh \
# 	&& ./bin/install_wine32.sh \
# 	&& ./bin/install_utilities.sh

# Install pip requirements
# COPY requirements.txt .
#RUN python -m pip install -r requirements.txt
COPY pyproject.toml .

# Download the latest installer
ADD https://astral.sh/uv/install.sh /uv-installer.sh

# Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

# Ensure the installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"

# RUN uv sync && source .venv/bin/activate
RUN uv sync && . .venv/bin/activate

WORKDIR /app
COPY . /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
RUN useradd -m -s /bin/bash vscode

USER appuser

# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
# CMD ["python", "convert_all.py"]

# CMD ["ls", "-d", "/app"]
