#!/usr/bin/env bash
# Prints a Markdown summary of a `dart test` / `flutter test` JSON results
# file (--file-reporter json:...), for $GITHUB_STEP_SUMMARY: one row per test.
# Used by legs whose results aren't (or not only) in the combined report.
#
# Usage: summarize-test-results.sh <title> <results.json>
set -uo pipefail

title=$1
file=$2

echo "### $title"
echo
if [ ! -s "$file" ]; then
  echo "No test results: the tests didn't run. See the job log."
  exit 0
fi

jq -rs '
  (map(select(.type == "testStart"))
    | map({key: (.test.id | tostring), value: .test.name})
    | from_entries) as $names
  | (map(select(.type == "error")) | map({key: (.testID | tostring), value: .error})
    | group_by(.key) | map({key: .[0].key, value: .[0].value}) | from_entries) as $errors
  | map(select(.type == "testDone" and (.hidden | not))) as $done
  | ($done | map(select(.skipped)) | length) as $skipped
  | ($done | map(select(.skipped | not) | select(.result == "success")) | length) as $passed
  | ($done | length) as $total
  | "\($passed) passed, \($total - $passed - $skipped) failed, \($skipped) skipped\n",
    "| Result | Test | Error |",
    "|---|---|---|",
    ($done[]
      | (.testID | tostring) as $id
      | "| \(if .skipped then "⏭️ skipped" elif .result == "success" then "✅ passed" else "❌ failed" end)"
        + " | \($names[$id] | gsub("\\|"; "\\\\|"))"
        + " | \(($errors[$id] // "") | split("\n") | map(select(test("\\S"))) | .[0:2] | join(" ") | .[0:200] | gsub("\\|"; "\\\\|")) |")
' "$file"
