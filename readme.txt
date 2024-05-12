Email login from config file -> mohamed 

script that search for keywords in websites -> abderrazzak

fork - thread ... -> bilal

script functioning :
a script that will be used to monitor websites given with keywords, the command should be running in background until user kill or stop it


first usage of script :  user should enter info that will be saved in configfile (sender email,password,email domaine, receivers email,...)

script usage : sudo(if necessary) monitor -k ... -w ... 

La syntaxe d’exécution du programme doit respecter la structure d’une commande de base
Linux, à savoir : programname [options] [paramètre]

params : 
    # ./ monitor.sh config
    -k: [keywords list] or keywordsfile.txt
    -w: [Websites list] or websites.txt
    -r: [receivers list] or receivers.txt
    -e: email:password:emaildomain:port
    -f: fork
    ...

Les sorties standard et d'erreur de votre script doivent être gérées de manière spécifique:
elles doivent être redirigées simultanément vers le terminal et vers un fichier de
journalisation nommé history.log, situé dans le répertoire /var/log/yourprogramname.

Chaque ligne dans ce fichier doit être précédée de la date et de l'heure au format yyyy-
mm-dd-hh-mm-ss, suivies du nom de l’utilisateur connecté et du type de message (INFOS



Gestion d’erreur :
Le programme doit activement gérer les erreurs résultant d'une utilisation incorrecte, telles
que le nombre inapproprié d'options ou l'échec d'un traitement exécuté par le script. Pour
chaque type d'erreur, un code spécifique doit être attribué afin de faciliter l'identification et
la résolution des problèmes. Voici quelques exemples de codes d'erreur :

o 100 : Option saisie non existante
o 101 : Paramètre obligatoire manquant
o ...