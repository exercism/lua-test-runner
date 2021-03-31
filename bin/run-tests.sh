#! /bin/sh

# Synopsis:
# Test the test runner by running it against a predefined set of solutions 
# with an expected output.

# Output:
# Outputs the diff of the expected test results against the actual test results
# generated by the test runner.

# Example:
# ./bin/run-tests.sh

exit_code=0

# Iterate over all test directories
for test_dir in tests/*; do
    test_dir_name="$(basename $test_dir)"
    test_dir_path="$(realpath $test_dir)"
    results_file="results.json"
    results_file_path="${test_dir}/results.json"
    expected_results_file="expected_results.json"
    expected_results_file_path="${test_dir}/expected_results.json"    

    if [ "${test_dir_name}" != "output" ] && [ -f "${expected_results_file_path}" ]; then
        bin/run.sh "${test_dir_name}" "${test_dir}" "${test_dir}"

        # Normalize the number of seconds to the solution in the results file
        sed -i -E 's/[0-9]+\.[0-9]+ seconds//' "${results_file_path}"

        echo "${test_dir_name}: comparing ${results_file} to ${expected_results_file}"
        diff "${results_file_path}" "${expected_results_file_path}"

        if [ $? -ne 0 ]; then
            exit_code=1
        fi
    fi
done

exit ${exit_code}
