#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>

// The function to be executed by threads
void *myThreadFun(void *vargp)
{
    // Store the value argument passed to this thread
    char *cmd = (char *)vargp;
    system(cmd);
}

int main(int argc, char **argv)
{
    if (argc > 2 && strcmp(argv[1], "-t") == 0)
    {
        pthread_t tid;

        if (pthread_create(&tid, NULL, myThreadFun, (void *)argv[2]) == EXIT_FAILURE)
            return EXIT_FAILURE;

        printf("%ld\n", tid);

        pthread_exit(NULL);
    }
    else if (argc > 2 && strcmp(argv[1], "-f") == 0)
    { // default value running as proccess
        pid_t pid = fork();

        if (pid < 0)
            return EXIT_FAILURE;

        if (pid == 0)
            system(argv[2]);
        if (pid > 0)
            printf("%d\n", pid);
    }
    else
    {
        fprintf(stderr, "Incorrect Argument Passed , Usage:  [-t|-f] COMMAND\n");

        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
