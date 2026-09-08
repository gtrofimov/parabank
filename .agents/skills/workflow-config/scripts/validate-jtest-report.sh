#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
mode="${1:-ut}"
report_dir="${2:-}"
[[ "$mode" == sa || "$mode" == ut ]] || { echo "Usage: $0 <sa|ut> <report-dir>" >&2; exit 2; }
[[ -n "$report_dir" && -f "$report_dir/report.xml" ]] || { echo "Missing report XML" >&2; exit 2; }

report_file="$report_dir/report.xml"
grep -q "build.id=$JTEST_BUILD_ID" "$report_file" || { echo "Report build ID mismatch" >&2; exit 2; }
grep -q "dtp.project=$DTP_PROJECT" "$report_file" || { echo "Report project mismatch" >&2; exit 2; }
grep -q "report.coverage.images=$DTP_UT_COVERAGE_IMAGES" "$report_file" || {
    echo "UT coverage image association missing or unexpanded" >&2
    exit 2
}
grep -q "report.coverage.static.images=$DTP_SOATEST_COVERAGE_IMAGES" "$report_file" || {
    echo "FT coverage image association missing or unexpanded" >&2
    exit 2
}

if [[ "$mode" == ut ]]; then
    test_errors=$(grep -o 'status="err"' "$report_file" | wc -l || true)
    test_failures=$(grep -o 'status="fail"' "$report_file" | wc -l || true)
    auth_errors=$(grep -o 'authErr="[1-9][0-9]*;' "$report_file" | wc -l || true)
    auth_failures=$(grep -o 'authFail="[1-9][0-9]*;' "$report_file" | wc -l || true)
    [[ "$test_errors" == 0 && "$test_failures" == 0 && "$auth_errors" == 0 && "$auth_failures" == 0 ]] || {
        echo "UT report contains errors: status_err=$test_errors status_fail=$test_failures auth_err=$auth_errors auth_fail=$auth_failures" >&2
        exit 2
    }
fi

printf 'Jtest report valid: mode=%s report=%s\n' "$mode" "$report_file"