#include <stdio.h>
#include <sched.h>

void main() {
    printf("c-helper\n");
    int i = 0;
    while (1) {
        // i++;
        sched_yield();
    }
}