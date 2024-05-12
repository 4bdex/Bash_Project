#!/bin/bash

# Initialize arrays to store values
keywords=()
websites=()
log_file=""
a_flag=false

# Parse options and their arguments
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
                log_file="$1"
                shift
            else
                echo "Error: Missing argument for -l flag"
                exit 1
            fi
            ;;
        -a)
            # Set the flag if -a is provided
            a_flag=true
            shift
            ;;
        *)
            echo "Error: Unknown option $1"
            exit 1
            ;;
    esac
done

# Output the collected data
echo "Keywords: ${keywords[@]}"
echo "Websites: ${websites[@]}"
echo "Log File: $log_file"
if $a_flag; then
    echo "Option -a specified"
fi
