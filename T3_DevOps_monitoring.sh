#!/bin/bash

CONFIG_FILE="T3_DevOps_config.conf"

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
    answer=$(curl -s -o /dev/null -w "%{http_code}" "$ADDRESS") 
    local curl_exit_code=$?

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

main()
{
    send_request


}

main