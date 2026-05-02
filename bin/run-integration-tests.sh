#! /bin/sh

# Synopsis:
# Test the test runner by running it against all practice and concept exercises
# in the track.

# Arguments:
# --skip-clone: do not (re)clone the track; assume `./track` is already
#               populated. Used by run-integration-tests-in-docker.sh,
#               which clones on the host so the container image does
#               not need git.

# Output:
# Outputs errors for failed runs.

# Example:
# ./bin/run-integration-tests.sh

exit_code=0

if [ "$1" != "--skip-clone" ]; then
    rm -rf track
    git clone --depth 1 https://github.com/exercism/lua track
fi

# Iterate over all exercise directories
for exercise_dir in track/exercises/practice/* track/exercises/concept/*; do
    exercise_slug=$(basename "${exercise_dir}")
    exercise_dir_path=$(realpath "${exercise_dir}")
    results_file="results.json"
    results_file_path="${exercise_dir}/${results_file}"

    bin/run.sh "${exercise_slug}" "${exercise_dir_path}" "${exercise_dir_path}" > /dev/null

    if [ $? -ne 0 ]; then
        echo "error: failed to run tests for $exercise_slug"
        exit_code=1
    fi

    if ! grep -q '[^[:space:]]' "$results_file_path"; then
        echo "error: generated empty result for $exercise_slug"
        exit_code=1
    fi
done

exit ${exit_code}
