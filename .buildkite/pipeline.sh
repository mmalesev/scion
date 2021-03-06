#!/bin/bash

set -e

export BASE=".buildkite"
STEPS="$BASE/steps"
TRIGGERS="$BASE/triggers"

# if the pipeline is triggered from a PR, run a reduced pipeline
if [ -z "$RUN_ALL_TESTS" ]; then
    [ "$BUILDKITE_PULL_REQUEST" = "false" ] && export RUN_ALL_TESTS=y
fi

# begin the pipeline.yml file
"$BASE/common.sh"
echo "steps:"

# build scion image and binaries
cat "$STEPS/setup.yml"

# Print instructions for manual build
echo "- label: 'Print instructions to trigger acceptance tests as user'"
echo "  command: 'envsubst < $BASE/files/acceptance_trigger_instructions'"
echo "  env:"
# The DOLLAR variable is used to create a $ in the output of envsubst. https://stackoverflow.com/questions/24963705/is-there-an-escape-character-for-envsubst
echo "    DOLLAR: '$'"
# build images together with unit tests
if [ "$RUN_ALL_TESTS" = "y" ]; then
    cat "$STEPS/build_all.yml"
fi

# Linting and Unit tests
cat "$STEPS/test.yml"

# we need to wait for the build_all step
if [ "$RUN_ALL_TESTS" = "y" ]; then
echo "- wait"
fi

# integration testing
"$STEPS/integration"

# conditionally run more tests
if [ "$RUN_ALL_TESTS" = "y" ]; then
    # docker integration testing
    cat "$STEPS/docker-integration.yml"
    # acceptance testing
    cat "$TRIGGERS/acceptance-trigger.yml"
fi

# deploy
cat "$STEPS/deploy.yml"
