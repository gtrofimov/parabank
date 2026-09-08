#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
mode="${1:-ut}"
data_file="${2:-target/jtest/jtest.data.json}"
[[ "$mode" == sa || "$mode" == ut ]] || { echo "Usage: $0 <sa|ut> [data-file]" >&2; exit 2; }
[[ -f "$data_file" ]] || { echo "Missing Jtest data: $data_file" >&2; exit 2; }

for source_file in pom.xml src/main/java; do
    [[ ! -e "$source_file" || "$source_file" -ot "$data_file" ]] || {
        echo "Jtest data older than $source_file" >&2
        exit 2
    }
done

if [[ "$mode" == ut && -d target/test-classes ]]; then
    orphaned=$(comm -23 \
        <(find target/test-classes -name '*.class' | sed 's|target/test-classes/||;s|\.class$||;s|\$.*||' | sort -u) \
        <(find src/test/java -name '*.java' | sed 's|src/test/java/||;s|\.java$||' | sort -u))
    [[ -z "$orphaned" ]] || {
        echo "Orphaned compiled tests found; run clean before UT" >&2
        printf '%s\n' "$orphaned" >&2
        exit 2
    }
fi

printf 'Jtest data valid: mode=%s file=%s\n' "$mode" "$data_file"