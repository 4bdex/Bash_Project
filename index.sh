# script functioning :
# a script that will be used to monitor websites given with keywords, the command should be running in background until user kill or stop it


# first usage of script :  user should enter info that will be saved in configfile (sender email,password, receivers email,email domaine,...)

# script usage : sudo(if necessary) monitor -k ... -w ...

# params :
#     -a: if option provided , keywords should not exists
#     -k: [keywords list] or keywordsfile.txt
#     -w: [Websites list] or websites.txt
#     -r: [receivers list] or receivers.txt
#     -e: email:password:emaildomain:port
#     -f: fork
#     ...

# implementation

#!/bin/bash

# check if the script is running as root
# if [ "$EUID" -ne 0 ]
# then echo "Please run as root"
#     exit
# fi

# check if the script is running with the right number of arguments
# if [ "$#" -ne 2 ]
#   then echo "Please provide the right number of arguments"
#   exit
# fi

# get keywords and websites from the user , this should check if user provided a list of keywords or a file containing keywords, same for websites

# get the keywords from file , if not a file get the list
# exemple -k test.com test.ma or -k file.txt

#!/bin/bash

#!/bin/bash

while getopts ":k:" opt; do
  case $opt in
    k)
      # Split the argument by comma
      IFS=',' read -ra ADDR <<< "$OPTARG"
      for i in "${ADDR[@]}"; do
        if [[ -f $i ]]; then
          # If it's a file, read the file
          keywords=$(cat "$i")
        else
          # If it's not a file, treat it as a list
          keywords=$i
        fi
        echo "Keywords: $keywords"
      done
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

echo "Keywords: $keywords"
