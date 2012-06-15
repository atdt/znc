SHELL    := /bin/sh

# Support out-of-tree builds
srcdir   := .
VPATH    := .

CXX      := g++
CXXFLAGS :=    -D_FORTIFY_SOURCE=2 -O2 -Wall -W -Wno-unused-parameter -Woverloaded-virtual -Wshadow -D_THREAD_SAFE -pthread   -I..
LDFLAGS  := 
LIBS     := -pthread -lssl -lcrypto -lz  

TARGETS  := ConfigTest EscapeTest
OBJS     := $(addsuffix .o, $(TARGETS))
ZNC_OBJS := Config.o ZNCDebug.o FileUtils.o Utils.o ZNCString.o MD5.o SHA256.o
ZNC_OBJS := $(addprefix ../, $(ZNC_OBJS))

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

.PHONY: test

all: $(TARGETS)

ConfigTest: ConfigTest.o
	$(E) Linking $@...
	$(Q)$(CXX) $(LDFLAGS) -o $@ $< $(ZNC_OBJS) $(LIBS)

EscapeTest: EscapeTest.o
	$(E) Linking $@...
	$(Q)$(CXX) $(LDFLAGS) -o $@ $< $(ZNC_OBJS) $(LIBS)

%.o: %.cpp Makefile
	@mkdir -p .depend
	$(E) Building $@...
	$(Q)$(CXX) $(CXXFLAGS) -c -o $@ $< -MMD -MF .depend/$@.dep

test: $(TARGETS)
	for test in $(TARGETS) ; do \
		./$$test || exit 1 ; \
	done
