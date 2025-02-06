#!/bin/bash

# Log file
LOG_FILE="/var/log/git-update-fan.log"

# Log function
log_message() {
    echo "$(date) - $1" >> "$LOG_FILE"
}

# Change to script directory
cd /usr/local/bin || {
    log_message "ERROR: Could not change to /usr/local/bin"
    exit 1
}

# Pull latest changes
log_message "Starting git update"
git reset --hard origin/master
GIT_RESULT=$(git pull origin master 2>&1)
PULL_STATUS=$?

if [ $PULL_STATUS -eq 0 ]; then
    log_message "Git pull successful: $GIT_RESULT"
    # Restart service only if there were actual updates
    if [[ $GIT_RESULT != *"Already up to date"* ]]; then
        systemctl restart fan-control
        log_message "Fan control service restarted"
    else
        log_message "No updates needed"
    fi
else
    log_message "ERROR: Git pull failed: $GIT_RESULT"
fi
