# syntax=docker/dockerfile:1

# Specify the Python version as an argument for flexibility
ARG PYTHON_VERSION=3.10.12
FROM python:${PYTHON_VERSION}-slim as base

# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create necessary directories
RUN mkdir -p /vol/media /vol/static

# Create a non-privileged user and change ownership of the directories
RUN adduser --disabled-password --gecos '' user && \
    chown -R user:user /vol/ && \
    chmod -R 755 /vol/

# Set the working directory
WORKDIR /app

# Copy requirements.txt and install dependencies with caching
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --no-cache-dir -r requirements.txt

# Install git and ffmpeg in a single RUN command to reduce image layers
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the whisper package from GitHub
RUN pip install "git+https://github.com/openai/whisper.git"

# Switch to the non-privileged user
USER user

# Copy the source code into the container
COPY ./app /app

# Expose the port that the application listens on
EXPOSE 80

# Run the application
CMD ["uvicorn", "main:app", "--reload", "--port", "80", "--host", "0.0.0.0"]
