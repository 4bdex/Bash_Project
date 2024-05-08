Email login from config file -> mohamed 

script that search for keywords in websites -> abderrazzak

fork - thread ... -> bilal

script functioning :

first usage of script :  user should enter info that will be saved in configfile (sender email,password, receivers email,email domaine,...)

script usage : sudo(if necessary) monitor -k ... -w ... 

params : 
    -k: [keywords list] or keywordsfile.txt
    -w: [Websites list] or websites.txt
    -r: [receivers list] or receivers.txt
    -e: email:password:emaildomain:port
    -f: fork
    ...