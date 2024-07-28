# Use Ubuntu as the base image
FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

# Update the sources list to use the South African mirror
RUN sed -i 's|archive.ubuntu.com|ubuntu.mirror.ac.za|' /etc/apt/sources.list \
    && sed -i 's|security.ubuntu.com|ubuntu.mirror.ac.za|' /etc/apt/sources.list

# Install necessary packages
RUN apt-get update --fix-missing && apt-get install -y \
    curl \
    sudo \
    unzip \
    git \
    libicu-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Find the next available user ID and group ID
RUN export UID=$(awk -F: '{if ($3 >= 1000 && $3 < 65534) print $3+1}' /etc/passwd | sort -n | tail -1) && \
    export GID=$(awk -F: '{if ($3 >= 1000 && $3 < 65534) print $3+1}' /etc/group | sort -n | tail -1) && \
    groupadd -g $GID myuser && \
    useradd -u $UID -g $GID -m -s /bin/bash myuser && \
    echo "Created user 'myuser' with UID $UID and GID $GID" && \
    id myuser

# Give 'myuser' sudo privileges
RUN echo "myuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/myuser

# Set proper permissions for the necessary directories
RUN mkdir -p /actions-runner/_diag && chown -R myuser:myuser /actions-runner /home/myuser

# Download and extract actions-runner
WORKDIR /actions-runner
RUN curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz \
    && tar xzf actions-runner.tar.gz \
    && chown -R myuser:myuser /actions-runner

# Switch to the non-root user 'myuser'
USER myuser

# Install Packages
RUN sudo apt-get update && sudo apt-get install -y \
    xz-utils \
    jq

# Configure the GitHub Actions local runner with the provided token
ARG GITHUB_ACCESS_TOKEN
ARG RUNNER_NAME
RUN ./config.sh --url https://github.com/Dario-Maselli/WebDevEssentials --token $GITHUB_ACCESS_TOKEN --name $RUNNER_NAME

# Specify the full path to the run.sh script
CMD ["./run.sh"]

####### DOCKER STEPS ########
# Build the image:
# docker build -t web_dev_essentials_runner --build-arg RUNNER_NAME=NEROSERVER --build-arg GITHUB_ACCESS_TOKEN=1234 .
#
# Then run the container:
# docker run -d web_dev_essentials_runner