#!/bin/bash

# Vérifier si le nombre d'arguments est correct
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <email1> <mot_de_passe_application_specifique> <Domaine_Name> <fichier_emails>"
    exit 1
fi

email1=""
mot_de_passe_app_specifique=""
domaine_Name=""
fichier=$1
message=$2
fichier_emails=$3

# Vérifier si le fichier d'emails existe
if [ ! -f "$fichier_emails" ]; then
    echo "Le fichier d'emails $fichier_emails n'existe pas."
    exit 1
fi


# Lecture de la première ligne du fichier
while read -r email password domain
do
    # Stockage des données dans des variables
    email1="$email"
    mot_de_passe_app_specifique="$password"
    domaine_Name="$domain"
    break # Sortie après lecture de la première ligne
done < "$fichier"

cat>/etc/ssmtp/ssmtp.conf<<EOF
root=$email1
mailhub=$domaine_Name
AuthUser=$email1
AuthPass=$mot_de_passe_app_specifique
UseSTARTTLS=yes
EOF


# Lire chaque email du fichier et envoyer le message "Hello, World!" à chaque adresse email
while IFS= read -r email; do
    echo "Sending 'Hello, World' to $email"
    echo "$message" | mail -s "Hello" -r "$email1" "$email"
done < "$fichier_emails"

echo "Tous les emails ont été envoyés avec succès!"