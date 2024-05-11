#!/bin/bash
# usgae : sudo monitor.sh -k keyword -w website [-a] (-a option is used to check if the keyword does not exist on the website)

# Constants
CONFIG_FILE="config.txt"
# get History log file path from config file
HISTORY_LOG=$(grep -i "history_log" "$CONFIG_FILE" | cut -d'=' -f2)

# Initialize variables
keyword=""
website=""
should_exist="true" # Default value if -a option is not provided

# Check if the keyword exists on the website
# Returns 0 if the keyword is found, 1 otherwise
check_keyword_in_website() {
    local keyword="$1"
    local website="$2"
    local should_exist="$3"
    
    # Get the website content
    local website_content=$(curl -s "$website")
    
    # Check if the keyword exists in the website content
    if [ "$should_exist" = "true" ]; then
        [[ "$website_content" == *"$keyword"* ]]
    else
        [[ "$website_content" != *"$keyword"* ]]
    fi
}

# Parse command-line arguments
while getopts ":k:w:a" opt; do
    case ${opt} in
        k) 
            keyword="$OPTARG"
            ;;
        w) 
            website="$OPTARG"
            ;;
        a) 
            should_exist="false" # Reverse the logic if -a is provided
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            echo "Usage: $0 -k keyword -w website [-a]" >&2
            exit 1
            ;;
    esac
done

# Check if the keyword and the website are provided
if [ -z "$keyword" ] || [ -z "$website" ]; then
    echo "Please provide both keyword and website"
    echo "Usage: $0 -k keyword -w website [-a]" >&2
    exit 1
fi

# Log the keyword and the website in the history log
# check if the history log file exists
if [ ! -f "$HISTORY_LOG" ]; then
    # Create the history log file if it doesn't exist (/var/log/monitor/history.log)
    mkdir -p "$(dirname "$HISTORY_LOG")"
    touch "$HISTORY_LOG"
fi
echo "Keyword: $keyword, Website: $website" >> "$HISTORY_LOG"

# Check if the keyword exists on the website
if check_keyword_in_website "$keyword" "$website" "$should_exist"; then
    echo "true"
else
    echo  "false"
fi

# Print the keyword and the website
echo "history log: $HISTORY_LOG"
echo "Should exist: $should_exist"
echo "Keyword: $keyword"
echo "Website: $website"
