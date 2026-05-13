#!/usr/bin/env bash
set -euo pipefail

# Plan implemented by this script:
# 1) Resolve a coverage XML input with sensible defaults.
# 2) Parse Jtest coverage XML quickly in one awk pass.
# 3) Compute per-file and per-method coverable/covered/uncovered metrics.
# 4) Rank files and methods by uncovered gaps to prioritize unit test creation.
# 5) Emit structured CSV for skill-side formatting and reporting.

usage() {
    cat <<'EOF'
Usage: coverage-gap-analysis.sh [options]

Options:
  -x, --coverage-xml PATH   Coverage XML path.
                           Default lookup order:
                           1) target/jtest/baseline/coverage.xml
                           2) report/coverage.xml
                           3) target/jtest/coverage.xml
  -n, --top N               Number of rows to print after ranking.
                           Use 0 for all rows. Default: 20
    -m, --method-top N        Number of method rows to print.
                                                     Use 0 for all rows. Default: same as --top
  -i, --include REGEX       Include only file paths matching REGEX.
    -o, --output FORMAT       Output format: csv, md, or text. Default: csv
    --no-methods              Disable method-level output.
      --all                 Include files with zero uncovered elements.
  -h, --help                Show help.

Examples:
  bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh
  bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh --top 50
  bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh --include "src/main/java/com/parasoft/parabank/web/controller/"
    bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh --output csv --top 0 > target/jtest/coverage-gaps.csv
EOF
}

resolve_default_coverage_xml() {
    local repo_root=$1
    local candidate

    for candidate in \
        "$repo_root/target/jtest/baseline/coverage.xml" \
        "$repo_root/report/coverage.xml" \
        "$repo_root/target/jtest/coverage.xml"
    do
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

coverage_xml=""
top_n=20
method_top=""
include_regex=""
output_format="csv"
show_all=0
include_methods=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        -x|--coverage-xml)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for $1" >&2
                exit 2
            fi
            coverage_xml=$2
            shift 2
            ;;
        -n|--top)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for $1" >&2
                exit 2
            fi
            top_n=$2
            shift 2
            ;;
        -i|--include)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for $1" >&2
                exit 2
            fi
            include_regex=$2
            shift 2
            ;;
        -m|--method-top)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for $1" >&2
                exit 2
            fi
            method_top=$2
            shift 2
            ;;
        -o|--output)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for $1" >&2
                exit 2
            fi
            output_format=$2
            shift 2
            ;;
        --no-methods)
            include_methods=0
            shift
            ;;
        --all)
            show_all=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! [[ "$top_n" =~ ^[0-9]+$ ]]; then
    echo "Invalid --top value: $top_n (expected non-negative integer)" >&2
    exit 2
fi

if [[ -z "$method_top" ]]; then
    method_top=$top_n
fi

if ! [[ "$method_top" =~ ^[0-9]+$ ]]; then
    echo "Invalid --method-top value: $method_top (expected non-negative integer)" >&2
    exit 2
fi

if [[ "$output_format" != "csv" && "$output_format" != "md" && "$output_format" != "text" ]]; then
    echo "Invalid --output value: $output_format (expected csv, md, or text)" >&2
    exit 2
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../../.." && pwd)

if [[ -z "$coverage_xml" ]]; then
    if ! coverage_xml=$(resolve_default_coverage_xml "$repo_root"); then
        echo "No coverage XML found. Expected one of:" >&2
        echo "  $repo_root/target/jtest/baseline/coverage.xml" >&2
        echo "  $repo_root/report/coverage.xml" >&2
        echo "  $repo_root/target/jtest/coverage.xml" >&2
        exit 1
    fi
fi

if [[ ! -f "$coverage_xml" ]]; then
    echo "Coverage XML file not found: $coverage_xml" >&2
    exit 1
fi

raw_file=$(mktemp)
sorted_file=$(mktemp)
selected_file=$(mktemp)
method_raw_file=$(mktemp)
method_sorted_file=$(mktemp)
method_selected_file=$(mktemp)

cleanup() {
    rm -f "$raw_file" "$sorted_file" "$selected_file" "$method_raw_file" "$method_sorted_file" "$method_selected_file"
}
trap cleanup EXIT

awk -v include_regex="$include_regex" -v show_all="$show_all" -v include_methods="$include_methods" -v file_out="$raw_file" -v method_out="$method_raw_file" '
function get_attr(text, attr,    pattern, value) {
    pattern = attr "=\"[^\"]*\""
    if (match(text, pattern) == 0) {
        return ""
    }
    value = substr(text, RSTART + length(attr) + 2, RLENGTH - length(attr) - 3)
    return value
}

function decode_xml(text,    out) {
    out = text
    gsub(/&lt;/, "<", out)
    gsub(/&gt;/, ">", out)
    gsub(/&amp;/, "\\&", out)
    gsub(/&quot;/, "\"", out)
    gsub(/&apos;/, sprintf("%c", 39), out)
    return out
}

function add_elements(store, loc, item_ref, elems,    count, parts, i, elem, file_key, method_key) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", elems)
    if (elems == "") {
        return
    }

    count = split(elems, parts, /[[:space:]]+/)
    for (i = 1; i <= count; i++) {
        elem = parts[i]
        if (elem == "") {
            continue
        }
        file_key = loc SUBSEP elem
        if (store == "static") {
            static_elements[file_key] = 1
        } else {
            covered_elements[file_key] = 1
        }

        if (include_methods == 1 && item_ref != "") {
            method_key = loc SUBSEP item_ref SUBSEP elem
            if (store == "static") {
                static_method_elements[method_key] = 1
            } else {
                covered_method_elements[method_key] = 1
            }
        }
    }
}

BEGIN {
    in_locations = 0
    current_loc = ""
    current_dyn_item = ""
}

{
    line = $0

    if (line ~ /<Locations>/) {
        in_locations = 1
    } else if (line ~ /<\/Locations>/) {
        in_locations = 0
    }

    if (in_locations == 1 && line ~ /<Loc /) {
        loc_ref = get_attr(line, "locRef")
        file_path = get_attr(line, "resProjPath")
        if (loc_ref != "" && file_path != "") {
            loc_to_path[loc_ref] = file_path
        }
    }

    if (line ~ /<CvgData /) {
        current_loc = get_attr(line, "locRef")
        current_dyn_item = ""
    } else if (line ~ /<\/CvgData>/) {
        current_loc = ""
        current_dyn_item = ""
    }

    if (include_methods == 1 && current_loc != "" && line ~ /<Item /) {
        item_ref = get_attr(line, "itemRef")
        item_name = decode_xml(get_attr(line, "name"))
        if (item_ref != "" && item_name != "" && item_ref != "1") {
            method_name[current_loc SUBSEP item_ref] = item_name
        }
    }

    if (current_loc != "" && line ~ /<StatCvg /) {
        add_elements("static", current_loc, get_attr(line, "itemRef"), get_attr(line, "elems"))
    }

    if (current_loc != "" && line ~ /<DynCvg /) {
        current_dyn_item = get_attr(line, "itemRef")
    } else if (current_loc != "" && line ~ /<\/DynCvg>/) {
        current_dyn_item = ""
    }

    if (current_loc != "" && current_dyn_item != "" && line ~ /<CtxCvg /) {
        add_elements("covered", current_loc, current_dyn_item, get_attr(line, "elemRefs"))
    }
}

END {
    for (key in static_elements) {
        split(key, parts, SUBSEP)
        loc_ref = parts[1]
        coverable_by_loc[loc_ref]++
        if (key in covered_elements) {
            covered_by_loc[loc_ref]++
        }
    }

    for (loc_ref in loc_to_path) {
        file_path = loc_to_path[loc_ref]
        coverable = coverable_by_loc[loc_ref] + 0
        covered = covered_by_loc[loc_ref] + 0

        if (coverable == 0) {
            continue
        }

        uncovered = coverable - covered
        coverage_pct = (covered * 100.0) / coverable

        if (include_regex != "" && file_path !~ include_regex) {
            continue
        }

        if (show_all == 0 && uncovered <= 0) {
            continue
        }

        printf "%s\t%d\t%d\t%d\t%.2f\n", file_path, coverable, covered, uncovered, coverage_pct >> file_out
    }

    if (include_methods == 1) {
        for (key in static_method_elements) {
            split(key, parts, SUBSEP)
            loc_ref = parts[1]
            item_ref = parts[2]
            method_key = loc_ref SUBSEP item_ref
            method_coverable[method_key]++
            if (key in covered_method_elements) {
                method_covered[method_key]++
            }
        }

        for (method_key in method_coverable) {
            split(method_key, mp, SUBSEP)
            loc_ref = mp[1]
            item_ref = mp[2]
            file_path = loc_to_path[loc_ref]
            if (file_path == "") {
                continue
            }

            if (include_regex != "" && file_path !~ include_regex) {
                continue
            }

            coverable = method_coverable[method_key] + 0
            covered = method_covered[method_key] + 0
            if (coverable == 0) {
                continue
            }

            uncovered = coverable - covered
            if (show_all == 0 && uncovered <= 0) {
                continue
            }

            coverage_pct = (covered * 100.0) / coverable
            mname = method_name[method_key]
            if (mname == "") {
                mname = "itemRef " item_ref
            }

            printf "%s\t%s\t%d\t%d\t%d\t%.2f\n", file_path, mname, coverable, covered, uncovered, coverage_pct >> method_out
        }
    }
}
' "$coverage_xml"

sort -t $'\t' -k4,4nr -k2,2nr -k1,1 "$raw_file" > "$sorted_file"

if (( include_methods == 1 )); then
    sort -t $'\t' -k5,5nr -k3,3nr -k1,1 -k2,2 "$method_raw_file" > "$method_sorted_file"
fi

if (( top_n == 0 )); then
    cp "$sorted_file" "$selected_file"
else
    head -n "$top_n" "$sorted_file" > "$selected_file"
fi

if (( include_methods == 1 )); then
    if (( method_top == 0 )); then
        cp "$method_sorted_file" "$method_selected_file"
    else
        head -n "$method_top" "$method_sorted_file" > "$method_selected_file"
    fi
fi

scope_files=$(wc -l < "$sorted_file" | tr -d '[:space:]')
scope_coverable=$(awk -F $'\t' '{sum += $2} END {print sum + 0}' "$sorted_file")
scope_covered=$(awk -F $'\t' '{sum += $3} END {print sum + 0}' "$sorted_file")
scope_uncovered=$((scope_coverable - scope_covered))

scope_pct="0.00"
if (( scope_coverable > 0 )); then
    scope_pct=$(awk -v covered="$scope_covered" -v coverable="$scope_coverable" 'BEGIN { printf "%.2f", (covered * 100.0) / coverable }')
fi

method_count=0
method_coverable_total=0
method_covered_total=0
method_uncovered_total=0
method_pct="0.00"

if (( include_methods == 1 )); then
    method_count=$(wc -l < "$method_sorted_file" | tr -d '[:space:]')
    method_coverable_total=$(awk -F $'\t' '{sum += $3} END {print sum + 0}' "$method_sorted_file")
    method_covered_total=$(awk -F $'\t' '{sum += $4} END {print sum + 0}' "$method_sorted_file")
    method_uncovered_total=$((method_coverable_total - method_covered_total))

    if (( method_coverable_total > 0 )); then
        method_pct=$(awk -v covered="$method_covered_total" -v coverable="$method_coverable_total" 'BEGIN { printf "%.2f", (covered * 100.0) / coverable }')
    fi
fi

if [[ "$output_format" == "csv" ]]; then
    echo "rank,file,coverable_elements,covered_elements,uncovered_elements,coverage_percent"
    awk -F $'\t' 'BEGIN { OFS=","; rank=0 }
    {
        rank++
        gsub(/"/, "\x22\x22", $1)
        printf "%d,\"%s\",%s,%s,%s,%s\n", rank, $1, $2, $3, $4, $5
    }' "$selected_file"

    if (( include_methods == 1 )); then
        echo
        echo "method_rank,file,method,coverable_elements,covered_elements,uncovered_elements,coverage_percent"
        awk -F $'\t' 'BEGIN { OFS=","; rank=0 }
        {
            rank++
            gsub(/"/, "\x22\x22", $1)
            gsub(/"/, "\x22\x22", $2)
            printf "%d,\"%s\",\"%s\",%s,%s,%s,%s\n", rank, $1, $2, $3, $4, $5, $6
        }' "$method_selected_file"
    fi

    exit 0
fi

if [[ "$output_format" == "md" ]]; then
    echo "## Coverage Gap Summary"
    echo
    echo "| Metric | Value |"
    echo "| --- | ---: |"
    echo "| Coverage XML | \\`$coverage_xml\\` |"
    if [[ -n "$include_regex" ]]; then
        echo "| Include filter | \\`$include_regex\\` |"
    else
        echo "| Include filter | <none> |"
    fi
    echo "| Files in scope | $scope_files |"
    echo "| Coverable elements | $scope_coverable |"
    echo "| Covered elements | $scope_covered |"
    echo "| Uncovered elements | $scope_uncovered |"
    echo "| Coverage percent | ${scope_pct}% |"

    if (( include_methods == 1 )); then
        echo "| Methods in scope | $method_count |"
        echo "| Method coverable elements | $method_coverable_total |"
        echo "| Method covered elements | $method_covered_total |"
        echo "| Method uncovered elements | $method_uncovered_total |"
        echo "| Method coverage percent | ${method_pct}% |"
    fi

    echo
    if [[ "$scope_files" == "0" ]]; then
        echo "No matching files found for this coverage source and filter."
        exit 0
    fi

    echo "## File Gaps"
    echo
    echo "| Rank | File | Coverable | Covered | Uncovered | Coverage % |"
    echo "| ---: | --- | ---: | ---: | ---: | ---: |"
    awk -F $'\t' 'BEGIN { rank=0 }
    {
        rank++
        printf "| %d | %s | %s | %s | %s | %s%% |\n", rank, $1, $2, $3, $4, $5
    }' "$selected_file"

    if (( include_methods == 1 )) && [[ "$method_count" != "0" ]]; then
        echo
        echo "## Method Gaps"
        echo
        echo "| Rank | File | Method | Coverable | Covered | Uncovered | Coverage % |"
        echo "| ---: | --- | --- | ---: | ---: | ---: | ---: |"
        awk -F $'\t' 'BEGIN { rank=0 }
        {
            rank++
            printf "| %d | %s | %s | %s | %s | %s | %s%% |\n", rank, $1, $2, $3, $4, $5, $6
        }' "$method_selected_file"
    fi

    exit 0
fi

echo "Coverage XML: $coverage_xml"
if [[ -n "$include_regex" ]]; then
    echo "Include filter: $include_regex"
else
    echo "Include filter: <none>"
fi
echo "Files in scope: $scope_files"
echo "Coverable elements: $scope_coverable"
echo "Covered elements: $scope_covered"
echo "Uncovered elements: $scope_uncovered"
echo "Coverage percent: ${scope_pct}%"

if (( include_methods == 1 )); then
    echo "Methods in scope: $method_count"
    echo "Method coverage percent: ${method_pct}%"
fi

echo

if [[ "$scope_files" == "0" ]]; then
    echo "No matching files found for this coverage source and filter."
    exit 0
fi

printf "%-6s %-10s %-10s %-10s %-10s %s\n" "Rank" "Coverable" "Covered" "Uncovered" "Percent" "File"
printf "%-6s %-10s %-10s %-10s %-10s %s\n" "----" "---------" "-------" "---------" "-------" "----"

rank=0
while IFS=$'\t' read -r file_path coverable covered uncovered percent; do
    rank=$((rank + 1))
    printf "%-6s %-10s %-10s %-10s %-10s %s\n" "$rank" "$coverable" "$covered" "$uncovered" "${percent}%" "$file_path"
done < "$selected_file"

if (( include_methods == 1 )) && [[ "$method_count" != "0" ]]; then
    echo
    printf "%-6s %-10s %-10s %-10s %-10s %-46s %s\n" "Rank" "Coverable" "Covered" "Uncovered" "Percent" "Method" "File"
    printf "%-6s %-10s %-10s %-10s %-10s %-46s %s\n" "----" "---------" "-------" "---------" "-------" "------" "----"

    rank=0
    while IFS=$'\t' read -r file_path method_name coverable covered uncovered percent; do
        rank=$((rank + 1))
        printf "%-6s %-10s %-10s %-10s %-10s %-46s %s\n" "$rank" "$coverable" "$covered" "$uncovered" "${percent}%" "$method_name" "$file_path"
    done < "$method_selected_file"
fi