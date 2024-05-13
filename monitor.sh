#!/bin/bash


# Constants
CONFIG_FILE="config.txt"
MONITOR_SCRIPT="./check.sh" # usage ./check.sh -k keyword -w website [-a]
# get History log file path from config file
HISTORY_LOG=$(grep -i "HISTORY_LOG" "$CONFIG_FILE" | cut -d'=' -f2)
SMTP_CONFIG=$(grep -i "SMTP_CONFIG" "$CONFIG_FILE" | cut -d'=' -f2)

# Initialize variables
keywords=()
websites=()
receivers=()
email_config=""
log_directory=""
fork=false
threads=false
subshell=false
should_exist="true" # Default value if -a option is not provided
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
# Function to handle errors
handle_error() {
    local error_code=$1
    local error_message=$2
    # log the error message with error code and the code should be printed to the standard error
    log_message "ERROR $error_code" "$error_message"
    echo "Error $error_code: $error_message" >&2
    display_help
    exit "$error_code"
}
# trap any generated error to invoke the log_message function with error and error content
trap 'log_message "ERROR" "An error occurred in the script at line $LINENO"' ERR
# check if websites are valid
check_web_sites() {
    for website in "${websites[@]}"; do
        if ! curl --output /dev/null --silent --head --fail "$website"; then
            handle_error 404 "Website $website is not valid"
        fi
    done
}

# check if internet connection is available
check_internet_connection() {
    if ! ping -c 1 google.com &> /dev/null; then
        handle_error 503 "No internet connection"
    fi
}

# Function to check if the script is running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to check if the script is running with the right number of arguments
# the user can use help option to display the usage, so we don't need to check the number of arguments
#also same for reset option, other than that we need to check the number of arguments
check_arguments() {
    # check if minimum number of arguments is provided (-k and -w options are required)
    if [ "$#" -lt 4 ]; then
        handle_error 400 "Missing required arguments"
    fi
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

reset_default_parameters() {
    # Reset the default parameters from defaultconfig.txt
    # replace the default config file content with the config file content
     cat defaultconfig.txt > config.txt
    # empty the receivers list
    > "receivers.txt"
    # empty smtp config file
    > "$SMTP_CONFIG"
    #  set default history log file path in config file
    sed -i "s|HISTORY_LOG=.*|HISTORY_LOG=/var/log/monitor/history.log|" "$CONFIG_FILE"
    echo "Default parameters have been reset"
}

# Function to parse the command-line arguments
parse_arguments() {

while [[ $# -gt 0 ]]; do
    case "$1" in
        -k)
            shift
            # Add all following arguments until another flag is encountered to keywords array
            while [[ $# -gt 0 && ! $1 == -* ]]; do
                keywords+=("$1")
                shift
            done
            ;;
        -w)
            shift
            # Add all following arguments until another flag is encountered to websites array
            while [[ $# -gt 0 && ! $1 == -* ]]; do
                websites+=("$1")
                shift
            done
            ;;
        -l)
            shift
            # Check if there is an argument following -l flag
            if [[ $# -gt 0 && ! $1 == -* ]]; then
                log_directory="$1"
                shift
            else
                handle_error 400 "Missing argument for -l option"
            fi
            ;;
        -a)
            # Set the flag if -a is provided
            should_exist="false"
            shift
            ;;
        -f)
            # Set the flag if -f is provided
            fork=true
            shift
            ;;
        -t)
            # Set the flag if -t is provided
            threads=true
            shift
            ;;
        -s)
            # Set the flag if -s is provided
            subshell=true
            shift
            ;;
        :)
            handle_error 400 "Missing argument for -$OPTARG option"
            ;;
        *)
            handle_error 401 "Invalid option: $1"
            ;;
    esac
done
}

# Function to check if the required arguments are provided
check_required_arguments() {
    if [ ${#keywords[@]} -eq 0 ] || [ ${#websites[@]} -eq 0 ]; then
        handle_error 400 "Missing required arguments"
    fi
}

# Function to execute the monitoring script
execute_monitor_script() {
    # check if log directory not exist, 
    # replace log_directory if not empty to the log directory in the config file
    if [ -n "$log_directory" ]; then
        # if log directory isn't exist, create it
        if [ ! -d "$log_directory" ]; then
            mkdir -p "$log_directory"
            touch "$log_directory/history.log"
        fi
        HISTORY_LOG="$log_directory/history.log"
        # replace the log directory in the config file
        sed -i "s|HISTORY_LOG=.*|HISTORY_LOG=$HISTORY_LOG|" "$CONFIG_FILE"
    fi
    # Execute the monitoring script
    if [ "$fork" = true ]; then
        # Execute the program with fork
        echo "Executing the program with fork"
        # if should_exist is true, then the keywords should exist
            if [ "$should_exist" = true ]; then
                ./runas -f -k ${keywords[@]} -w ${websites[@]}
            else
                ./runas -f -k ${keywords[@]} -w ${websites[@]} -a
            fi
        elif [ "$threads" = true ]; then
        # Execute the program with threads
        echo "Executing the program with threads"                           
            if [ "$should_exist" = true ]; then
                ./runas -t -k ${keywords[@]} -w ${websites[@]}
            else
                ./runas -t -k ${keywords[@]} -w ${websites[@]} -a
            fi
        elif [ "$subshell" = true ]; then
        # Execute the program in a subshell
        echo "Executing the program in a subshell"
        # Execute the program in a subshell
            if [ "$should_exist" = true ]; then
                ./runas -s -k ${keywords[@]} -w ${websites[@]}
            else
                ./runas -s -k ${keywords[@]} -w ${websites[@]} -a
            fi
        
    else
        # Execute the program normally
        "$MONITOR_SCRIPT" -k "${keywords[@]}" -w "${websites[@]}" -a "$should_exist"
    fi
}


# Main function
main() {
    # if -h option is provided, display the help message
    if [ "$1" = "-h" ]; then
        display_help
    fi

    if [ "$1" = "config" ]; then
        echo "$SMTP_CONFIG"
        # if /etc/ssmtp/ssmtp.conf doesn't exist, create it
        if [ ! -f "$SMTP_CONFIG" ]; then
            touch "$SMTP_CONFIG"
        fi
        # ask user to provide the configuration file (email , password , domain:port , receivers list)
        echo "Please provide the email configuration"
        read -p "Email: " email
        read -p "Password: " password
        read -p "Email Domain: " domain

        # insert data in SMTP_CONFIG file
        # overwrite the email configuration
        echo "root=$email">> $SMTP_CONFIG
        echo "mailhub=$domain">> $SMTP_CONFIG
        echo "AuthUser=$email">> $SMTP_CONFIG
        echo "AuthPass=$password">> $SMTP_CONFIG
        echo "UseSTARTTLS=yes">> $SMTP_CONFIG
        
        # ask user to provide the receivers list
        echo "Please provide the receivers list"
        while true; do
            read -p "Receiver (q to stop): " receiver
            # if the receiver is empty, break the loop
            if [ -z "$receiver" ]; then
                continue
            fi
            if [ "$receiver" = "q" ]; then
                break
            fi
            # append the receiver to the receivers list
            receivers+=("$receiver")
        done
        # write the receivers list to the config file
        > "receivers.txt"
        for receiver in "${receivers[@]}"; do
            echo "$receiver" >> "receivers.txt"
        done
        exit 0
    fi
  
    # option to reset the default parameters
    if [ "$1" = "-r" ]; then
        check_root
        reset_default_parameters
        exit 0
    fi

    # check if config file exist if not or doesn't contain config print run ./main config to config
    if [ ! -f "$SMTP_CONFIG" ]; then
        echo "Please run './main.sh config' to provide the configuration"
        exit 1
    fi

    check_internet_connection
    check_root
    check_arguments "$@"
    parse_arguments "$@"
    check_required_arguments
    check_web_sites
    execute_monitor_script
}

# Run the main function
main "$@"
