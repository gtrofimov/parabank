#!/usr/bin/env bash
set -euo pipefail

catalina.sh run &
tomcat_pid=$!
cleanup() {
    kill "$tomcat_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for attempt in $(seq 1 60); do
    if curl -fsS --max-time 2 http://localhost:8080/parabank/ >/dev/null; then
        break
    fi
    if ! kill -0 "$tomcat_pid" 2>/dev/null; then
        wait "$tomcat_pid"
        exit 1
    fi
    if [[ "$attempt" == 60 ]]; then
        echo 'ParaBank did not become ready before database initialization.' >&2
        exit 1
    fi
    sleep 1
done

curl -fsS --max-time 30 -L http://localhost:8080/parabank/initializeDB.htm >/dev/null
printf '%s\n' 'ParaBank database initialized.'

wait "$tomcat_pid"
