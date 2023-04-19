#!/bin/bash

# Based on AWS default cloud9 script, this is an improved version for use with C9 and VSCODE
#
# cron - by means of /etc/crond.d/c9-automatic-shutdown - runs this script every minute
# the script schedules a shutdown in 'SHUTDOWN_TIMEOUT' minutes when instance is idle
# if whithin the shutdown timeout period activity is detected (e.g. reconnect), the shutdown is canceled

# idle detection is
# - no vfs connected
# - no vscode-server running

# shutdown creates a file /run/systemd/shutdown/scheduled.
# shutdown -c doesn't remove the file, the cancel_shutdown function does.
# the existence of the file is checked by is_shutting_down as a reliable indicator
# of a shutdown being scheduled. if not - just to be sure - pgrep is used to check
# if a shutdown process is running

# active ssh/ssm sessions are not taken into account for idle detection !!

# -- functions --

is_active()
{
    pgrep -f vfs-worker >/dev/null || pgrep -fa vscode-server | grep -v -F 'shellIntegration-bash.sh' >/dev/null
}

is_shutting_down() {
    local FILE
    FILE=/run/systemd/shutdown/scheduled
    if [[ -f "$FILE" ]]; then
        return 0
    else
        pgrep -f /sbin/shutdown >/dev/null
    fi
}

cancel_shutdown()
{
    sudo shutdown -c
    sudo rm -f /run/systemd/shutdown/scheduled
}

# -- main --

set -euo pipefail
CONFIG=$(cat /home/ec2-user/.c9/autoshutdown-configuration)
SHUTDOWN_TIMEOUT=${CONFIG#*=}
if ! [[ $SHUTDOWN_TIMEOUT =~ ^[0-9]*$ ]]; then
    echo "shutdown timeout is invalid in /home/ec2-user/.c9/autoshutdown-configuration"
    exit 1
fi

touch "/home/ec2-user/.c9/autoshutdown-timestamp"

if is_active; then
    if is_shutting_down; then
        cancel_shutdown
        echo "$(date): canceled shutdown "> "/home/ec2-user/.c9/autoshutdown-timestamp"
    fi
else
    if ! is_shutting_down ; then
        sudo shutdown -h $SHUTDOWN_TIMEOUT
        echo "$(date): initiated shutdown with waiting time of ${SHUTDOWN_TIMEOUT} minutes"> "/home/ec2-user/.c9/autoshutdown-timestamp"
    fi
fi
