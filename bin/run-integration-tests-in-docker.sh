#!/usr/bin/env bash
set -e

# Synopsis:
# Test the test runner by running it against all practice and concept exercises
# in the track in the test runner Docker image.

# Output:
# Outputs errors for failed runs.

# Example:
# ./bin/run-integration-tests-in-docker.sh

# Build the Docker image
docker build --rm -t exercism/lua-test-runner .

# Clone the track on the host. Doing this here (not inside the
# container) keeps git out of the production image.
rm -rf track
git clone https://github.com/exercism/lua track

# Run the Docker image using the settings mimicking the production environment
docker run \
    --rm \
    --mount type=bind,src="${PWD}/tests",dst=/opt/test-runner/tests \
    --mount type=bind,src="${PWD}/track",dst=/opt/test-runner/track \
    --mount type=tmpfs,dst=/tmp \
    --workdir /opt/test-runner \
    --entrypoint /opt/test-runner/bin/run-integration-tests.sh \
    exercism/lua-test-runner --skip-clone
