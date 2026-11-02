#!/usr/bin/env bash

# Demonstrates PID, PPID, pgrep, background jobs, and wait(2) in Bash.
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'EOF'
Usage:
  ./process_management.sh [number]
  ./process_management.sh worker {fibonacci|factorial|armstrong} number

The first form starts three child processes and monitors their PID/PPID.
EOF
}

is_non_negative_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

fibonacci() {
    local n=$1
    local first=0
    local second=1
    local next
    local i

    for ((i = 0; i < n; i++)); do
        next=$((first + second))
        first=$second
        second=$next
    done
    printf '%s\n' "$first"
}

factorial() {
    local n=$1
    local result=1
    local i

    for ((i = 2; i <= n; i++)); do
        result=$((result * i))
    done
    printf '%s\n' "$result"
}

is_armstrong() {
    local number=$1
    local original=$number
    local digits=${#number}
    local sum=0
    local digit

    while ((number > 0)); do
        digit=$((number % 10))
        sum=$((sum + digit ** digits))
        number=$((number / 10))
    done

    ((sum == original))
}

run_worker() {
    local task=$1
    local number=$2
    local result

    printf '[worker] PID=%s PPID=%s task=%s input=%s\n' \
        "$$" "$PPID" "$task" "$number"
    # Keep the worker visible briefly so the parent can inspect it with pgrep.
    sleep 0.2

    case "$task" in
        fibonacci)
            result=$(fibonacci "$number")
            printf '[worker] Fibonacci(%s) = %s\n' "$number" "$result"
            ;;
        factorial)
            result=$(factorial "$number")
            printf '[worker] Factorial(%s) = %s\n' "$number" "$result"
            ;;
        armstrong)
            if is_armstrong "$number"; then
                printf '[worker] %s is an Armstrong number\n' "$number"
            else
                printf '[worker] %s is not an Armstrong number\n' "$number"
            fi
            ;;
        *)
            printf 'Unknown task: %s\n' "$task" >&2
            return 2
            ;;
    esac
}

start_workers() {
    local number=$1
    local task
    local pid
    local -a pids=()

    printf 'Parent shell: PID=%s PPID=%s\n' "$$" "$PPID"
    printf '\nStarting child processes...\n'

    for task in fibonacci factorial armstrong; do
        "$SCRIPT_DIR/process_management.sh" worker "$task" "$number" &
        pid=$!
        pids+=("$pid")
        printf 'Started %-9s with PID=%s\n' "$task" "$pid"
    done

    # Give the workers enough time to appear in the process table.
    sleep 0.1
    printf '\nProcesses whose parent is PID %s (pgrep -P %s):\n' "$$" "$$"
    pgrep -a -P "$$" || printf 'No child processes are currently running.\n'

    printf '\nDetailed process information (ps):\n'
    ps -o pid=,ppid=,stat=,cmd= -p "$$" "${pids[@]}" 2>/dev/null || true

    printf '\nWaiting for child processes...\n'
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    printf 'All child processes completed.\n'
}

main() {
    if [[ "${1:-}" == "worker" ]]; then
        [[ $# -eq 3 ]] || { usage >&2; return 2; }
        is_non_negative_integer "$3" || {
            printf 'Number must be a non-negative integer: %s\n' "$3" >&2
            return 2
        }
        run_worker "$2" "$3"
        return
    fi

    [[ $# -le 1 ]] || { usage >&2; return 2; }
    local number=${1:-10}
    is_non_negative_integer "$number" || {
        printf 'Number must be a non-negative integer: %s\n' "$number" >&2
        return 2
    }
    start_workers "$number"
}

main "$@"
