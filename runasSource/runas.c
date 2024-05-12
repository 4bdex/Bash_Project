#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>

#define true 1
#define false 0

typedef short bool;

const char scriptName[] = "bash check.sh";

// The function to be executed by threads
void *myThreadFun(void *vargp)
{
    // Store the value argument passed to this thread
    char *cmd = (char *)vargp;
    system(cmd);
}
int main(int argc, char **argv)
{
    char keywords[1024] = {'\0'};
    char *websites[256];
    bool shouldExists = true; // search for the existance of the keywords or the inverse
    int numWebsites = 0;
    char *option;

    bool readingkeywords = false;
    bool readingwebsites = false;

    char command[1024];

    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-k") == 0)
        {
            readingkeywords = true;
            readingwebsites = false;
        }
        else if (strcmp(argv[i], "-w") == 0)
        {
            readingwebsites = true;
            readingkeywords = false;
        }
        else if (strcmp(argv[i], "-a") == 0)
        {
            shouldExists = false;
        }
        else if ((strcmp(argv[i], "-f") == 0) || (strcmp(argv[i], "-t") == 0) || (strcmp(argv[i], "-s") == 0))
        {
            readingkeywords = false;
            readingwebsites = false;

            option = argv[i];
        }
        else if (readingkeywords)
        {
            strcat(keywords, " ");
            strcat(keywords, argv[i]);
        }
        else if (readingwebsites)
        {
            websites[numWebsites] = argv[i];
            numWebsites++;
        }
        else
        {

            fprintf(stderr, "Incorrect Argument Passed , Usage:  [-t|-f|-s] [-a] -k KEYWORDS -w WEBSITES\n");
            return EXIT_FAILURE;
        }
    }

    /*
    printf("[*] option : %s \n ", option);
    printf("[*] should exist or not : %d\n", shouldExists);
    printf("keywords :  %s", keywords);
    printf("\nwebsites : ");
    for (int i = 0; i < numWebsites; i++)
        printf(" %s", websites[i]);
    */

    if (strcmp(option, "-t") == 0)
    {
        for (int i = 0; i < numWebsites; i++)
        {
            sprintf(command, "%s -k %s -w %s %s", scriptName, keywords, websites[i], ((shouldExists) ? "" : "-a"));

            pthread_t tid;

            if (pthread_create(&tid, NULL, myThreadFun, (void *)command) == EXIT_FAILURE)
                return EXIT_FAILURE;

            printf("[*] New thread runnig with tid : %ld command : [%s]\n", tid, command);
        }

        pthread_exit(NULL);
    }
    else if (strcmp(option, "-f") == 0)
    { // default value running as proccess

        for (int i = 0; i < numWebsites; i++)
        {
            sprintf(command, "%s -k %s -w %s %s", scriptName, keywords, websites[i], ((shouldExists) ? "" : "-a"));

            pid_t pid = fork();

            if (pid < 0)
                return EXIT_FAILURE;

            if (pid > 0)
                printf("[*] New proccess runnig with id : %d command : [%s]\n", pid, command);

            if (pid == 0)
            {
                system(command);
                break;
            }
        }
        while (wait(NULL) > 0) // wait for all child proccess to finish
            ;
    }
    else if (strcmp(option, "-s") == 0)
    {
        for (int i = 0; i < numWebsites; i++)
        {
            sprintf(command, "%s -k %s -w %s %s", scriptName, keywords, websites[i], ((shouldExists) ? "" : "-a"));

            printf("[*] New sub-shell runnig command : [%s]\n", command);

            system(command);
        }
    }

    return EXIT_SUCCESS;
}
