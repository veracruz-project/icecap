#include <string.h>

size_t strlen(const char *s)
{
	const char *start = s;
	for (; *s; s++);
	return s - start;
}
