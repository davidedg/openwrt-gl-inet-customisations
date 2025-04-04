#!/bin/ash

# This script runs a specified background script with lock management, logging,
# and timeout monitoring. It prevents concurrent runs, handles stale locks, and
# cleans up resources after execution. Default settings can be customized with
# command-line arguments.

PIDFILE=""

# Default values for parameters
LOGGING=false
LOG_TAG="$(basename "$0")"  # Default script name set to the filename itself
TIMEOUT=10                  # Default timeout in seconds
BACKGROUND_SCRIPT=""        # Background script to execute

# Usage function
usage() {
    cat <<EOF
Usage: $0 [-l] [-t log_tag] [-x timeout] [-s "background_script"]

Options:
  -l                      Enable logging to the system logger
  -t log_tag              Set the log tag (default is the script's filename)
  -x timeout              Set the timeout duration in seconds (default is 10)
  -s "background_script"  Specify the background script (remaining args passed)

Example:
  $0 -l -t myscript -x 20 -s ./my_script.sh arg1 arg2

EOF
}

# Command-line argument parsing
while getopts "lt:x:s:" opt; do
    case "$opt" in
        l) LOGGING=true ;;                          # Enable logging
        t) LOG_TAG="$OPTARG" ;;                     # Set custom log tag
        x) TIMEOUT="$OPTARG" ;;                     # Set custom timeout
        s) BACKGROUND_SCRIPT="$OPTARG" ;;           # Set background script path
        *) usage                                    # Display usage section on invalid arguments
           exit 1 ;;                                # Exit on error
    esac
done

shift $((OPTIND - 1))  # Shift off the processed options and flags

# Validate arguments
if [ -z "$BACKGROUND_SCRIPT" ]; then
    echo "Error: Background script is not provided. Use -s to specify it." >&2
    usage
    exit 1
fi

if ! [ "$TIMEOUT" -gt 0 ] 2>/dev/null; then
    echo "Error: Timeout must be a positive integer." >&2
    usage
    exit 1
fi

# Dynamically set the lock directory based on LOG_TAG
LOCKDIR="/tmp/${LOG_TAG}.lock"
PIDFILE="${LOCKDIR}/pid"
umask 077

# Functions
log() {
    [ "$LOGGING" = true ] && logger -t "$LOG_TAG" "$1"
}

acquire_lock() {
    if mkdir "$LOCKDIR" 2>/dev/null; then
        log "Lock acquired."
        trap "cleanup" EXIT
        echo $$ > "$PIDFILE"
        return 0
    fi
    log "Lock is already in use."
    return 1
}

cleanup() {
    rm -rf "$LOCKDIR"
}

handle_stale_lock() {
    log "Removing stale lock directory."
    rm -rf "$LOCKDIR"
    acquire_lock || { log "Failed to acquire lock after removing stale lock."; exit 1; }
}

check_pid() {
    if [ -f "$PIDFILE" ]; then
        if kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            log "Script is already running with PID $(cat "$PIDFILE")."
            exit 1
        else
            log "The process is no longer running."
            handle_stale_lock
        fi
    else
        log "No PID file found, but lock exists."
        handle_stale_lock
    fi
}

monitor_process() {
    local pid=$1
    local timeout=$2
    local interval=1 # Polling interval in seconds
    local elapsed=0

    while kill -0 "$pid" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout" ]; then
            log "Timeout reached. Process $pid did not complete in $timeout seconds. Killing."
            kill -9 "$pid" 2>/dev/null
            break
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    if ! kill -0 "$pid" 2>/dev/null; then
        log "Process $pid completed."
    fi
}

# Main script
if ! acquire_lock; then
    check_pid
fi

log "Starting background script: $BACKGROUND_SCRIPT with arguments: $*"

"$BACKGROUND_SCRIPT" "$@" &
bg_pid=$!

monitor_process "$bg_pid" "$TIMEOUT"
