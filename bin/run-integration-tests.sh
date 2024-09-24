#! /bin/sh

# Synopsis:
# Test the test runner by running it against all practice and concept exercises
# in the track.

# Output:
# Outputs errors for failed runs.

# Example:
# ./bin/run-integration-tests.sh

exit_code=0

rm -rf track
git clone https://github.com/exercism/lua track

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
