#include <setjmp.h>
#include <signal.h>

// HACK
#include <stdio.h>

int sigsetjmp(sigjmp_buf buf, int save)
{
    if ((buf->__fl = save)) {
        printf("warning: sigsetjmp(_, 0x%lx)\n", save); // HACK
    }
    return setjmp(buf);
}
