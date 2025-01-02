#!/bin/bash
MY_PATH="$(realpath ${BASH_SOURCE[0]})"
MY_DIR="$(dirname ${MY_PATH})"
BIN_DIR="${MY_DIR}/ltp_bin"

# Check if the Docker image exists
IMAGE_NAME="rdk-kirkstone:latest"  # Replace with your actual image name
if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" == "" ]]; then
    echo "Docker image ${IMAGE_NAME} not found. Please build the image first."
    exit 1
else
    echo "Docker image ${IMAGE_NAME} found. Running docker-run.sh..."
    ./docker-run.sh /bin/bash
fi

# Navigate to the ltp directory
cd ltp/ || { echo "Directory ltp not found"; exit 1; }

# Run autotools
make autotools

# Source the environment setup
. /opt/toolchains/rdk-glibc-x86_64-arm-toolchain/environment-setup-armv7vet2hf-neon-oe-linux-gnueabi

# Display the compiler
echo "Using compiler: $CC"
echo "PATH: $PATH"
# Configure with specified prefix and host
./configure --prefix="${BIN_DIR}" --host=arm

# Build the project
make

# Install the built project
make install

