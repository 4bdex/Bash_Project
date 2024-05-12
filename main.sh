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

# Function to get the keywords from the user
get_keywords() {
    echo "get_keywords"
    # Flag to indicate if we're currently collecting keywords
    collecting_keywords=false
    
    # Iterate through the arguments
    for arg in "$@"; do
        # check if argument is a file
        if [ -f "$arg" ]; then
            # Read the file contents and add each line to the keywords array
            while IFS= read -r line || [ -n "$line" ]
            do
                keywords+=("$line")
            done < "$arg"
            break
        fi
        
        # If -k option is found
        if [ "$arg" = "-k" ]; then
            # Set flag to start collecting keywords
            collecting_keywords=true
            elif [ "$collecting_keywords" = true ]; then
            # if args start with - then it's an option
            if [[ "$arg" == -* ]]; then
                # If we are currently collecting keywords, add the argument to the array
                break
            fi
            # else break the loop

              keywords+=("$arg")
            
        fi
    done
}

# Function to get the websites from the user
get_websites() {
    echo "get_websites"
    
    # Flag to indicate if we're currently collecting websites
    collecting_websites=false
    
    # Iterate through the arguments
    for arg in "$@"; do
        # check if argument is a file
        if [ -f "$arg" ]; then
            # Read the file contents and add each line to the websites array
            while IFS= read -r line || [ -n "$line" ]
            do
                websites+=("$line")
            done < "$arg"
            break
        fi
        
        # If -w option is found
        if [ "$arg" = "-w" ]; then
            # Set flag to start collecting websites
            collecting_websites=true
            elif [ "$collecting_websites" = true ]; then
            # if args start with - then it's an option
            if [[ "$arg" != -* ]]; then
                # If we are currently collecting websites, add the argument to the array
                websites+=("$arg")
            fi
            
        fi
    done
}

# Function to get the receivers from the user
get_receivers() {
    # Initialize an empty array to store arguments after -d
    receivers=()
    
    # Flag to indicate if we're currently collecting receivers
    collecting_receivers=false
    
    # Iterate through the arguments
    for arg in "$@"; do
        # check if argument is a file
        if [ -f "$arg" ]; then
            # Read the file contents and add each line to the receivers array
            while IFS= read -r line || [ -n "$line" ]
            do
                receivers+=("$line")
            done < "$arg"
            break
        fi
        
        # If -d option is found
        if [ "$arg" = "-d" ]; then
            # Set flag to start collecting receivers
            collecting_receivers=true
            elif [ "$collecting_receivers" = true ]; then
            # If we are currently collecting receivers, add the argument to the array
            receivers+=("$arg")
        fi
    done
}

# Function to get the email configuration from the user
get_email_config() {
    # Iterate through the arguments
    for arg in "$@"; do
        # If -e option is found
        if [ "$arg" = "-e" ]; then
            # Get the next argument
            shift
            email_config="$1"
            break
        fi
    done
}

# Function to get the log directory from the user
get_log_directory() {
    # Iterate through the arguments
    for arg in "$@"; do
        # If -l option is found
        if [ "$arg" = "-l" ]; then
            # Get the next argument
            shift
            log_directory="$1"
            break
        fi
    done
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
    for arg in $@ ; do
        if [ "$arg" == '-k' ]; then
                itskeyword=1
                itswebsite=0

        elif [ "$arg" == '-w' ]; then
                itskeyword=0
                itswebsite=1

        #if the argument is an option, then we should skip it
        # -a without argument
        elif [ "$arg" == "-a" ]; then
            echo "option -a provided"
                should_exist="false"
        elif [ "$arg" == "-f" ]; then
                echo "option -f provided"
                fork=true
        elif [ "$arg" == "-t" ]; then
                echo "option -t provided"
                threads=true
        elif [ "$arg" == "-s" ]; then
                echo "option -s provided"
                subshell=true
        elif [ "$arg" == "-r" ]; then
                # Reset default parameters (admin only)
                echo "Reset default parameters"
                exit 0
        elif [ $itskeyword -eq 1 ]; then
                keywords="$keywords $arg"

        elif [ $itswebsite -eq 1 ]; then
                websites="$websites $arg"
        fi
       
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

# Function to log the keyword and the website in the history log
log_history() {
    # Check if the history log file exists
    if [ ! -f "$HISTORY_LOG" ]; then
        echo "History log file not found"
        exit 1
    fi
    
    # Log the keyword and the website in the history log
    for keyword in "${keywords[@]}"; do
        for website in "${websites[@]}"; do
            echo "$(date +"%Y-%m-%d-%H-%M-%S") : $(whoami) : INFO : Checking keyword '$keyword' in website '$website'" >> "$HISTORY_LOG"
        done
    done
}

# Function to execute the monitoring script
execute_monitor_script() {
    # Log the keyword and the website in the history log
    log_history
    
    # Execute the monitoring script
    if [ "$fork" = true ]; then
        # Execute the program with fork
        echo "Executing the program with fork"
        # "$MONITOR_SCRIPT" -k "${keywords[@]}" -w "${websites[@]}" -a "$should_exist"
        echo "./runas/runas -f "$MONITOR_SCRIPT -k ${keywords[@]} -w ${websites[@]} -a $should_exist""

        elif [ "$threads" = true ]; then
        # Execute the program with threads
        echo "Executing the program with threads"
                                           
        ./runas/runas -t "$MONITOR_SCRIPT -k ${keywords[@]} -w ${websites[@]} -a $should_exist"
        ./runas/runas -f -k Gmail help -w https://www.google.com/ https://doc.ubuntu-fr.org/tutoriel/script_shell -a
        elif [ "$subshell" = true ]; then
        # Execute the program in a subshell
        echo "Executing the program in a subshell"
          echo "PID: $$"
        # Execute the program in a subshell
        (
            "$MONITOR_SCRIPT" -k "${keywords[@]}" -w "${websites[@]}" -a "$should_exist"
        )
        
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

        cat>SMTP_CONFIG<<EOF
        root=$email
        mailhub=$domain
        AuthUser=$email
        AuthPass=$password
        UseSTARTTLS=yes
        EOF
        
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
    check_root
    check_arguments "$@"
    parse_arguments "$@"
    check_required_arguments
    execute_monitor_script
}

# Run the main function
main "$@"
