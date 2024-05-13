#!/bin/bash

# this is the main script

# pour les messages de sortie standard et ERROR pour les messages d'erreur). Par exemple:
# ▪ yyyy-mm-dd-hh-mm-ss : username : INFOS : message de l’output standard
# ▪ yyyy-mm-dd-hh-mm-ss : username : ERROR : message de l’erreur standard

# Gestion d’erreur :
# Le programme doit activement gérer les erreurs résultant d'une utilisation incorrecte, telles
# que le nombre inapproprié d'options ou l'échec d'un traitement exécuté par le script. Pour
# chaque type d'erreur, un code spécifique doit être attribué afin de faciliter l'identification et
# la résolution des problèmes. Voici quelques exemples de codes d'erreur :

# o 100 : Option saisie non existante
# o 101 : Paramètre obligatoire manquant
# o ...

# Votre script doit incorporer des commandes ou des outils Unix/Linux de base. Il peut
# également faire appel à des scripts externes développés en Bash, en langage C, etc.
# o Il doit prendre en charge une ou plusieurs données en paramètre, avec au moins une
# donnée obligatoire.
# o Le script doit aussi proposer, au moins, six options obligatoires, telles que :
# -a: if option provided , keywords should not exists
# -k: [keywords list] or keywordsfile.txt
# -w: [Websites list] or websites.txt
# -d: [receivers list] or receivers.txt
# -e: email:password:emaildomain:port
# ▪ -h (help): Affiche une documentation détaillée du programme.
# ▪ -f (fork): Permet une exécution par création de sous-processus avec fork.
# ▪ -t (thread): Permet une exécution par threads.
# ▪ -s (subshell): Exécute le programme dans un sous-shell.
# ▪ -l (log): Permet de spécifier un répertoire pour le stockage du fichier de
# journalisation.
# ▪ -r (restore): Réinitialise les paramètres par défaut, utilisable uniquement par des
# administrateurs.
# ▪ ...

# Constants
CONFIG_FILE="config.txt"
MONITOR_SCRIPT="./check.sh" # usage ./check.sh -k keyword -w website [-a]
# get History log file path from config file
HISTORY_LOG=$(grep -i "history_log" "$CONFIG_FILE" | cut -d'=' -f2)
SMTP_CONFIG=$(grep -i "smtp_config" "$CONFIG_FILE" | cut -d'=' -f2)

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

# check if websites are valid
check_web_sites() {
    for website in "${websites[@]}"; do
        if ! curl --output /dev/null --silent --head --fail "$website"; then
            log_message "ERROR" "Website $website is not valid"
            echo "Website $website is not valid"
            exit 1
        fi
    done
}

# check if internet connection is available
check_internet_connection() {
    if ! ping -c 1 google.com &> /dev/null; then
        log_message "ERROR" "No internet connection"
        echo "No internet connection"
        exit 1
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
        echo "Please provide the right number of arguments"
        echo "Usage: $0 -k keywords -w websites" >&2
        echo "Use -h option for more details" >&2
        exit 1
    fi
}


# display help message
display_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -a                   If provided, keywords should not exist"
    echo "  -k [keywords]        Keywords list or keywordsfile.txt"
    echo "  -w [websites]        Websites list or websites.txt"
    echo "  -d [receivers]       Receivers list or receivers.txt"
    echo "  -e [email_config]    Email configuration: email:password:emaildomain:port"
    echo "  -h                   Display this help message"
    echo "  -f                   Execute the program with fork"
    echo "  -t                   Execute the program with threads"
    echo "  -s                   Execute the program in a subshell"
    echo "  -l [log_directory]   Specify a directory for the log file"
    echo "  -r                   Reset default parameters (admin only)"
    exit 0
}


# Function to parse the command-line arguments
parse_arguments() {
#     for arg in $@ ; do

#         if [ "$arg" == '-k' ]; then
#                 itskeyword=1
#                 itswebsite=0

#         elif [ "$arg" == '-w' ]; then
#                 itskeyword=0
#                 itswebsite=1
#         #if the argument is an option, then we should skip it
#         # -a without argument
#         elif [ "$arg" == "-a" ]; then
#                 should_exist="false"
#                 itskeyword=0
#                itswebsite=0
#         elif [ "$arg" == "-f" ]; then
#                 fork=true
#                 itskeyword=0
#                itswebsite=0
#         elif [ "$arg" == "-t" ]; then
#                 threads=true
#                 itskeyword=0
#                itswebsite=0
#         elif [ "$arg" == "-s" ]; then
#                 subshell=true
#                 itskeyword=0
#                 itswebsite=0
#         elif [ "$arg" == "-r" ]; then
#                 # Reset default parameters (admin only)
#                 echo "Reset default parameters"
#                 exit 0
#                 itskeyword=0
#                 itswebsite=0
#         elif [ "$arg" == "-l" ]; then
#                 # -l option is provided, get the log directory from the next argument (exemple: -k key1 key2 -w web1 -l /var/log)
#                 log_directory=$2
#                 itskeyword=0
#                 itswebsite=0

#         elif [ $itskeyword -eq 1 ]; then
#                 keywords="$keywords $arg"

#         elif [ $itswebsite -eq 1 ]; then
#                 websites="$websites $arg"
#         fi
# done
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
                echo "Error: Missing argument for -l flag"
                exit 1
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
        -r)
            # Reset default parameters (admin only)
            echo "Reset default parameters"
            exit 0
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument"
            exit 1
            ;;
        *)
            echo "Error: Unknown option $1"
            exit 1
            ;;
    esac
done
}

# Function to check if the required arguments are provided
check_required_arguments() {
    if [ ${#keywords[@]} -eq 0 ] || [ ${#websites[@]} -eq 0 ]; then
        echo "Please provide all required arguments"
        echo "Usage: $0 -k keyword -w website" >&2
        echo "Use -h option for more details" >&2
        exit 1
    fi
}

# Function to execute the monitoring script
execute_monitor_script() {
    # replace log_directory if not empty to the log directory in the config file
    if [ -n "$log_directory" ]; then
        # if log directory isn't exist, create it
        if [ ! -d "$log_directory" ]; then
            mkdir -p "$log_directory"
            touch "$log_directory/history.log"
        fi
        HISTORY_LOG="$log_directory/history.log"
        echo "HIstory log: $HISTORY_LOG"
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
        echo "Executing the program normally"
        echo "shoud exist: $should_exist"
        echo "PID: $$"
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
        # ask user to provide the configuration file (email , password , domain:port , receivers list)
        echo "Please provide the email configuration"
        read -p "Email: " email
        read -p "Password: " password
        read -p "Email Domain: " domain

        # insert data in SMTP_CONFIG

        # cat>SMTP_CONFIG<<EOF
        # root=$email
        # mailhub=$domain
        # AuthUser=$email
        # AuthPass=$password
        # UseSTARTTLS=yes
        # EOF
        
        # ask user to provide the receivers list
        echo "Please provide the receivers list"
        while true; do
            read -p "Enter receiver email (or 'q' to quit): " receiver
            if [ "$receiver" = "q" ]; then
                break
            fi
            # add receiver to receivers.txt file
            echo "$receiver" >> receivers.txt
        done
        echo "">> receivers.txt
        exit 0
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
