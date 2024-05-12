#!/bin/bash

# Vérifier si le nombre d'arguments est correct
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <email1> <mot_de_passe_application_specifique> <Domaine_Name> <fichier_emails>"
    exit 1
fi

email1=$1
mot_de_passe_app_specifique=$2
domaine_Name=$3
fichier_emails=$4


if [ ! -f "$fichier_emails" ]; then
    echo "Le fichier d'emails $fichier_emails n'existe pas."
    exit 1
fi


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
   echo "Hello, World! this is just a test" | mail -s "Hello" -r "$email1" "$email"
done < "$fichier_emails"

echo "Tous les emails ont été envoyés avec succès!"