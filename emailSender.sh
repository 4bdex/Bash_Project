#!/bin/bash


# variable
#  get email_config from config file
EMAIL_CONFIG=$(grep -i "EMAIL_CONFIG" "$CONFIG_FILE" | cut -d'=' -f2)
# Vérifier si le nombre d'arguments est correct
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <subject> <message>"
    exit 1
fi

subject=$1
message=$2
fichier_emails=receivers.txt

# Vérifier si le fichier d'emails n'existe pas ou est vide
if [ ! -s "$fichier_emails" ]; then
    echo "Le fichier $fichier_emails n'existe pas ou est vide"
    exit 1
fi


# get email from /etc/ssmtp/ssmtp.conf file
email1=$(grep -i "AuthUser" /etc/ssmtp/ssmtp.conf | cut -d'=' -f2)

# Lire chaque email du fichier et envoyer le message "Hello, World!" à chaque adresse email
while IFS= read -r email; do
    echo "Sending 'Hello, World' to $email"
    echo "$message" | mail -s "Hello" -r "$email1" "$email"
done < "$fichier_emails"

echo "Tous les emails ont été envoyés avec succès!"