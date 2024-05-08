Email login from config file -> mohamed 

script that search for keywords in websites -> abderrazzak

fork - thread ... -> bilal

script functioning :
a script that will be used to monitor websites given with keywords, the command should be running in background until user kill or stop it


first usage of script :  user should enter info that will be saved in configfile (sender email,password, receivers email,email domaine,...)

script usage : sudo(if necessary) monitor -k ... -w ... 

params : 
    -a: if option provided , keywords should not exists
    -k: [keywords list] or keywordsfile.txt
    -w: [Websites list] or websites.txt
    -r: [receivers list] or receivers.txt
    -e: email:password:emaildomain:port
    -f: fork
    ...