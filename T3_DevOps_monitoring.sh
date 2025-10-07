#!/bin/bash

CONFIG_FILE="T3_DevOps_config.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file $CONFIG_FILE not found!" >&2
    exit 1
fi

source "$CONFIG_FILE"

add_log()
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_PATH" 
}

check_answer_site()
{
    local answer="$1"
    local valid_codes="200 201 204"

    for code in $valid_codes; do
        if [ "$answer" -eq "$code" ] 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

send_request()
{
    local answer
    local curl_exit_code
    
    answer=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$ADDRESS" 2>/dev/null)
    curl_exit_code=$?

    if [ $curl_exit_code -ne 0 ]; then
        add_log "ERROR: Curl failed with exit code $curl_exit_code"
        return 1
    fi

    if check_answer_site "$answer"; then
        add_log "INFO: Server responded with HTTP $answer"
        return 0
    else
        add_log "ERROR: Monitoring server unavailable. HTTP response: $answer"
        return 1
    fi
}

find_process_pid()
{
    ps aux 2>/dev/null | \
    grep -F "$PROCESS_NAME" | \
    grep -v grep | \
    grep -v $$ | \
    awk 'NR==1 {print $2}'
}

get_previous_pid()
{
    if [ -f "$PID_FILE" ]; then
        tail -n 1 "$PID_FILE" 2>/dev/null
    else
        echo ""
    fi
}

check_process_restart()
{
    local current_pid="$1"
    local previous_pid="$2"
    
    if [ -n "$previous_pid" ] && [ "$current_pid" != "$previous_pid" ]; then
        add_log "INFO: Process \"$PROCESS_NAME\" was restarted. Old PID: $previous_pid, New PID: $current_pid"
        return 0
    else
        return 1
    fi
}

handle_running_process()
{
    local current_pid="$1"
    local previous_pid="$2"
    
    check_process_restart "$current_pid" "$previous_pid"
    
    if ! send_request; then
        true
    fi
    
    echo "$current_pid" >> "$PID_FILE"
}

handle_stopped_process()
{
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
    fi
}

process_monitoring_logic()
{
    local current_pid="$1"
    
    if [ -n "$current_pid" ] && [[ "$current_pid" =~ ^[0-9]+$ ]]; then
        handle_running_process "$current_pid" "$(get_previous_pid)"
    else
        handle_stopped_process
    fi
}

main()
{
    local current_pid
    
    current_pid=$(find_process_pid)
    process_monitoring_logic "$current_pid"
}

main