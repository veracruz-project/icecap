include Makefile.libfdt
LIBFDT_LIB = libfdt.a

INSTALL = install
CPPFLAGS = -I .

DESTDIR =
PREFIX =
LIBDIR = $(PREFIX)/lib
INCLUDEDIR = $(PREFIX)/include

.PHONY: all
all: $(LIBFDT_LIB)

$(LIBFDT_LIB): $(LIBFDT_OBJS)
	$(AR) $(ARFLAGS) $@ $^

.PHONY: install install-lib install-includes
install: install-includes install-lib

install-lib: $(LIBFDT_LIB)
	$(INSTALL) -d $(DESTDIR)$(LIBDIR)
	$(INSTALL) -m 644 $(LIBFDT_LIB) $(DESTDIR)$(LIBDIR)

install-includes: $(LIBFDT_INCLUDES)
	$(INSTALL) -d $(DESTDIR)$(INCLUDEDIR)
	$(INSTALL) -m 644 $(LIBFDT_INCLUDES) $(DESTDIR)$(INCLUDEDIR)
