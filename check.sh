#!/bin/bash
# Usage: sudo monitor.sh -k keyword1 keyword2 ... -w website1 website2 ... -a true|false

echo "PID of the script: $$"

# Constants
CONFIG_FILE="config.txt"

# Get History log file path from config file
HISTORY_LOG=$(grep -i "history_log" "$CONFIG_FILE" | cut -d'=' -f2)

# Initialize arrays
keywords=()
websites=()
should_exist=""
itskeyword=0
itswebsite=0



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

echo "Keywords: ${keywords[@]}"
echo "Websites: ${websites[@]}"
echo "Should exist: $should_exist"

# Log the keywords and the websites in the history log
# Check if the history log file exists
if [ ! -f "$HISTORY_LOG" ]; then
    # Create the history log file if it doesn't exist (/var/log/monitor/history.log)
    mkdir -p "$(dirname "$HISTORY_LOG")"
    touch "$HISTORY_LOG"
fi

# Iterate over each website and check if the keywords exists based on the should_exist value

# for website in "${websites[@]}"; do
#     echo "Checking $website"
#     for keyword in "${keywords[@]}"; do
#         echo "Checking for keyword: $keyword"
#         # Check if the keyword exists in the website
#         if curl -s "$website" | grep -q "$keyword"; then
#             # Log the keyword and website in the history log
#             echo "$(date) - $keyword found in $website" >> "$HISTORY_LOG"
#             if [ "$should_exist" = false ]; then
#                 echo "Keyword $keyword found in $website"
#             fi
#         else
#             # Log the keyword and website in the history log
#             echo "$(date) - $keyword not found in $website" >> "$HISTORY_LOG"
#             if [ "$should_exist" = true ]; then
#                 echo "Keyword $keyword not found in $website"
#                 break
#             fi
#         fi
#     done
# done
# a while loop to check for each website if the keywords exist or not based on the should_exist value, 
# if result is true, then it will break the loop , remove the website from the list and continue to the next website
# print the result of the check for each website passed the check

while [ ${#websites[@]} -gt 0 ]; do
    website=${websites[0]}
    echo "Checking $website"
    for keyword in "${keywords[@]}"; do
        echo "Checking for keyword: $keyword"
        # Check if the keyword exists in the website
        websiteContent=$(curl -s -L "$website")
        # comparisation should not be case sensitive
        if echo "$websiteContent" | grep -qi "$keyword"; then
            if [ "$should_exist" = true ]; then
                echo "Keyword $keyword found in $website"
                # Remove the website from the list
                websites=("${websites[@]:1}")
                break
            fi
        else
            if [ "$should_exist" = false ]; then
                echo "Keyword $keyword not found in $website"
                # Remove the website from the list
                websites=("${websites[@]:1}")
                break
            fi
        fi
    done
done

# end script 
# kill the script

