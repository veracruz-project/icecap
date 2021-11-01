#define xend(s) end(s)
#define end(s) s ## _end
#define xstr(s) str(s)
#define str(s) #s

#ifndef SECTION
#define SECTION _embedded_files
#endif

.section .SECTION,"aw"
.globl SYMBOL, xend(SYMBOL)
SYMBOL:
.incbin xstr(FILE)
xend(SYMBOL):
