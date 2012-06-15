SHELL       := /bin/sh

# Support out-of-tree builds
srcdir      := .
VPATH       := .

prefix      := /usr/local
exec_prefix := ${prefix}
datarootdir := ${prefix}/share
bindir      := ${exec_prefix}/bin
datadir     := ${datarootdir}
sysconfdir  := ${prefix}/etc
libdir      := ${exec_prefix}/lib
includedir  := ${prefix}/include
sbindir     := ${exec_prefix}/sbin
localstatedir := ${prefix}/var
CXX      := g++
CXXFLAGS := -I$(srcdir)/include -Iinclude    -D_FORTIFY_SOURCE=2 -O2 -Wall -W -Wno-unused-parameter -Woverloaded-virtual -Wshadow -D_THREAD_SAFE -pthread  
LDFLAGS  := 
LIBS     := -pthread -lssl -lcrypto -lz  
LIBZNC   := 
LIBZNCDIR:= 
MODDIR   := ${exec_prefix}/lib/znc
DATADIR  := ${datarootdir}/znc
PKGCONFIGDIR := $(libdir)/pkgconfig
INSTALL         := /usr/bin/install -c
INSTALL_PROGRAM := ${INSTALL}
INSTALL_SCRIPT  := ${INSTALL}
INSTALL_DATA    := ${INSTALL} -m 644

LIB_SRCS  := ZNCString.cpp Csocket.cpp znc.cpp IRCNetwork.cpp User.cpp IRCSock.cpp \
	Client.cpp Chan.cpp Nick.cpp Server.cpp Modules.cpp MD5.cpp Buffer.cpp Utils.cpp \
	FileUtils.cpp HTTPSock.cpp Template.cpp ClientCommand.cpp Socket.cpp SHA256.cpp \
	WebModules.cpp Listener.cpp Config.cpp ZNCDebug.cpp
LIB_SRCS  := $(addprefix src/,$(LIB_SRCS))
BIN_SRCS  := src/main.cpp
LIB_OBJS  := $(patsubst %cpp,%o,$(LIB_SRCS))
BIN_OBJS  := $(patsubst %cpp,%o,$(BIN_SRCS))
CLEAN     := znc src/*.o core core.*
DISTCLEAN := Makefile config.log config.status znc-config znc-buildmod .depend \
	modules/.depend modules/Makefile man/Makefile znc.pc znc-uninstalled.pc

CXXFLAGS += -D_MODDIR_=\"$(MODDIR)\" -D_DATADIR_=\"$(DATADIR)\"

ifneq "$(V)" ""
VERBOSE=1
endif
ifeq "$(VERBOSE)" ""
Q=@
E=@echo
C=-s
else
Q=
E=@\#
C=
endif

.PHONY: all man modules clean distclean install
.SECONDARY:

all: znc man modules $(LIBZNC)
	@echo ""
	@echo " ZNC was successfully compiled. You may use"
	@echo " '$(MAKE) install' to install ZNC to '$(prefix)'."
	@echo " You can then use '$(bindir)/znc --makeconf'"
	@echo " to generate a config file."
	@echo ""
	@echo " If you need help with using ZNC, please visit our wiki at:"
	@echo "   http://znc.in"

ifeq "$(LIBZNC)" ""
OBJS := $(BIN_OBJS) $(LIB_OBJS)

znc: $(OBJS)
	$(E) Linking znc...
	$(Q)$(CXX) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)
else
znc: $(BIN_OBJS) $(LIBZNC)
	$(E) Linking znc...
	$(Q)$(CXX) $(LDFLAGS) -o $@ $(BIN_OBJS) -L. -lznc -Wl,-rpath,$(LIBZNCDIR) $(LIBS)

$(LIBZNC): $(LIB_OBJS)
	$(E) Linking $(LIBZNC)...
	$(Q)$(CXX) $(LDFLAGS) -shared -o $@ $(LIB_OBJS) $(LIBS)
endif

man:
	@$(MAKE) -C man $(C)

modules: $(LIBZNC)
	@$(MAKE) -C modules $(C)

clean:
	rm -rf $(CLEAN)
	@$(MAKE) -C modules clean;
	@$(MAKE) -C man clean

distclean: clean
	rm -rf $(DISTCLEAN)

src/%.o: src/%.cpp Makefile
	@mkdir -p .depend src
	$(E) Building core object $*...
	$(Q)$(CXX) $(CXXFLAGS) -c -o $@ $< -MD -MF .depend/$*.dep -MT $@

install: znc $(LIBZNC)
	test -d $(DESTDIR)$(bindir) || $(INSTALL) -d $(DESTDIR)$(bindir)
	test -d $(DESTDIR)$(includedir)/znc || $(INSTALL) -d $(DESTDIR)$(includedir)/znc
	test -d $(DESTDIR)$(PKGCONFIGDIR) || $(INSTALL) -d $(DESTDIR)$(PKGCONFIGDIR)
	test -d $(DESTDIR)$(MODDIR) || $(INSTALL) -d $(DESTDIR)$(MODDIR)
	test -d $(DESTDIR)$(DATADIR) || $(INSTALL) -d $(DESTDIR)$(DATADIR)
	cp -R $(srcdir)/webskins $(DESTDIR)$(DATADIR)
	find $(DESTDIR)$(DATADIR)/webskins -type d -exec chmod 0755 '{}' \;
	find $(DESTDIR)$(DATADIR)/webskins -type f -exec chmod 0644 '{}' \;
	$(INSTALL_PROGRAM) znc $(DESTDIR)$(bindir)
	$(INSTALL_SCRIPT) znc-config $(DESTDIR)$(bindir)
	$(INSTALL_SCRIPT) znc-buildmod $(DESTDIR)$(bindir)
	$(INSTALL_DATA) $(srcdir)/include/znc/*.h $(DESTDIR)$(includedir)/znc
	$(INSTALL_DATA) include/znc/zncconfig.h $(DESTDIR)$(includedir)/znc
	$(INSTALL_DATA) znc.pc $(DESTDIR)$(PKGCONFIGDIR)
	@$(MAKE) -C modules install DESTDIR=$(DESTDIR);
	if test -n "$(LIBZNC)"; then \
		test -d $(DESTDIR)$(LIBZNCDIR) || $(INSTALL) -d $(DESTDIR)$(LIBZNCDIR) || exit 1 ; \
		$(INSTALL_PROGRAM) $(LIBZNC) $(DESTDIR)$(LIBZNCDIR) || exit 1 ; \
	fi
	@$(MAKE) -C man install DESTDIR=$(DESTDIR)

uninstall:
	rm $(DESTDIR)$(bindir)/znc
	rm $(DESTDIR)$(bindir)/znc-config
	rm $(DESTDIR)$(bindir)/znc-buildmod
	rm $(DESTDIR)$(includedir)/znc/*.h
	rm $(DESTDIR)$(PKGCONFIGDIR)/znc.pc
	rm -rf $(DESTDIR)$(DATADIR)/webskins
	if test -n "$(LIBZNC)"; then \
		rm $(DESTDIR)$(LIBZNCDIR)/$(LIBZNC) || exit 1 ; \
		rmdir $(DESTDIR)$(LIBZNCDIR) || exit 1 ; \
	fi
	@$(MAKE) -C man uninstall DESTDIR=$(DESTDIR)
	@if test -n "modules"; then \
		$(MAKE) -C modules uninstall DESTDIR=$(DESTDIR); \
	fi
	rmdir $(DESTDIR)$(bindir)
	rmdir $(DESTDIR)$(includedir)/znc
	rmdir $(DESTDIR)$(PKGCONFIGDIR)
	@echo "Successfully uninstalled, but empty directories were left behind"

-include $(wildcard .depend/*.dep)
