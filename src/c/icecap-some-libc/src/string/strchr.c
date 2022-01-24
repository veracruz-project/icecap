#include <string.h>

char *strchr(const char *s, int c)
{
	c = (unsigned char)c;
	for (; *s && *s != c; s++);
	return *s ? (char *)s : NULL;
}
