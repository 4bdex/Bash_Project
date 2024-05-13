#!/bin/bash
# Usage: sudo monitor.sh -k keyword1 keyword2 ... -w website1 website2 ... -a true|false

# Constants
CONFIG_FILE="config.txt"

# Get History log file path from config file
HISTORY_LOG=$(grep -i "HISTORY_LOG" "$CONFIG_FILE" | cut -d'=' -f2)

# Initialize arrays
keywords=()
websites=()
should_exist=""
itskeyword=0
itswebsite=0

# Function to log that takes the error code and the message as arguments
log_message() {
        # Check if the history log file exists
    if [ ! -f "$HISTORY_LOG" ]; then
        # Create the history log file if it doesn't exist (/var/log/monitor/history.log)
        mkdir -p "$(dirname "$HISTORY_LOG")"
        touch "$HISTORY_LOG"
    fi
    # Get the current date and time
    current_date=$(date "+%Y-%m-%d %H:%M:%S")
    # Get the current user
    current_user=$(whoami)
    # Get the error type
    Type=$1
    # Get the message
    message=$2
    echo "$current_date : $current_user : $Type : $message" >> "$HISTORY_LOG"
}
# display help message
display_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  config               Configure the email settings and receivers list"
    echo "  -a                   If provided, keywords should not exist"
    echo "  -k                   Keywords list"
    echo "  -w                   Websites list"
    echo "  -d                   Receivers list"
    echo "  -h                   Display this help message"
    echo "  -f                   Execute the program with fork"
    echo "  -t                   Execute the program with threads"
    echo "  -s                   Execute the program in a subshell"
    echo "  -l [log_directory]   Specify a directory for the log file"
    echo "  -r                   Reset default parameters (admin only)"
    exit 0
}

# Parse command-line arguments
for arg in $* ; do

        if [ "$arg" == '-k' ]; then
                itskeyword=1
                itswebsite=0

        elif [ "$arg" == '-w' ]; then
                itskeyword=0
                itswebsite=1

        elif [ "$arg" == "-a" ]; then
                itskeyword=0
                itswebsite=0

        elif [ $itskeyword -eq 1 ]; then
                keywords+=("$arg")

        elif [ $itswebsite -eq 1 ]; then
                websites+=("$arg")
        else
                should_exist=$arg
        fi
done




# a while loop to check for each website if the keywords exist or not based on the should_exist value, 
# if result is true, then it will break the loop , remove the website from the list and continue to the next website
while [ ${#websites[@]} -gt 0 ]; do
    website=${websites[0]}
    echo "Checking $website"
    for keyword in "${keywords[@]}"; do
        echo "Checking for keyword: $keyword" #TODO: Remove this line
        # Check if the keyword exists in the website
        websiteContent=$(curl -s -L "$website")
        # comparisation should not be case sensitive
        if echo "$websiteContent" | grep -qi "$keyword"; then
            if [ "$should_exist" = true ]; then
                echo "Keyword $keyword found in $website"
                # send email to the admin
                # send_email "Keyword $keyword found in $website"
                log_message "INFO" "Keyword $keyword found in $website"
                # Remove the website from the list
                websites=("${websites[@]:1}")
                break
            fi
        else
            if [ "$should_exist" = false ]; then
                echo "Keyword $keyword not found in $website"
                 # send_email "Keyword $keyword found in $website"
                log_message "INFO" "Keyword $keyword not found in $website"
                # Remove the website from the list
                websites=("${websites[@]:1}")
                break
            fi
        fi
    done
done

# if an error occurs, the script will exit with an error code
trap 'log_message "ERROR" "An error occurred in the script at line $LINENO"' ERR
# end script 
# kill the script

