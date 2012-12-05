#
# Configuration
#

# CC
CC=gcc
# Path to parent kernel include files directory
LIBC_INCLUDE=/usr/include
# Libraries
ADDLIB=
# Linker flags
LDFLAG_STATIC=-Wl,-Bstatic
LDFLAG_DYNAMIC=-Wl,-Bdynamic

#
# Options
#

# Capability support (with libcap)
USE_CAP=yes
# sysfs support (with libsysfs - deprecated)
USE_SYSFS=no
# IDN support (experimental)
USE_IDN=no
# Do not use getifaddrs
WITHOUT_IFADDRS=no
# arping default device
ARPING_DEFAULT_DEVICE=eth0
# rdisc server (-r option) support
ENABLE_RDISC_SERVER=no
# ping6 source routing (deprecated by RFC5095)
ENABLE_PING6_RTHDR=no

# -------------------------------------
# What a pity, all new gccs are buggy and -Werror does not work. Sigh.
# CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -Werror -g
CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -g
CCOPTOPT=-O3
GLIBCFIX=-D_GNU_SOURCE
DEFINES=
LDLIB=

ifneq ($(USE_CAP),no)
	DEF_CAP = -DCAPABILITIES
	LIB_CAP = -lcap
endif

ifneq ($(USE_SYSFS),no)
	DEF_SYSFS = -DUSE_SYSFS
	LIB_SYSFS = -lsysfs
endif

ifneq ($(USE_IDN),no)
	DEF_IDN = -DUSE_IDN
ifeq ($(USE_IDN),static)
	LIB_IDN = $(LDFLAG_STATIC) -lidn $(LDFLAG_DYNAMIC)
else
	LIB_IDN = -lidn
endif
endif

ifneq ($(WITHOUT_IFADDRS),no)
	DEF_WITHOUT_IFADDRS = -DWITHOUT_IFADDRS
endif

ifneq ($(ENABLE_RDISC_SERVER),no)
	DEF_ENABLE_RDISC_SERVER = -DRDISC_SERVER
endif

ifneq ($(ENABLE_PING6_RTHDR),no)
	DEF_ENABLE_PING6_RTHDR = -DPING6_ENABLE_RTHDR
ifeq ($(ENABLE_PING6_RTHDR),RFC3542)
	DEF_ENABLE_PING6_RTHDR += -DPINR6_ENABLE_RTHDR_RFC3542
endif
endif

# -------------------------------------
IPV4_TARGETS=tracepath ping clockdiff rdisc arping tftpd rarpd
IPV6_TARGETS=tracepath6 traceroute6 ping6
TARGETS=$(IPV4_TARGETS) $(IPV6_TARGETS)

CFLAGS=$(CCOPTOPT) $(CCOPT) $(GLIBCFIX) $(DEFINES)
LDLIBS=$(LDLIB) $(ADDLIB)

LASTTAG:=`git describe HEAD | sed -e 's/-.*//'`
TAG:=`date +s%Y%m%d`

# -------------------------------------
.PHONY: all ninfod clean distclean man html check-kernel modules snapshot

all: $(TARGETS)

%.s: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -S -o $@
%.o: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -o $@
$(TARGETS): %: %.o
	$(LINK.o) $^ $(LIB_$@) $(LDLIBS) -o $@

# -------------------------------------
# arping
DEF_arping = $(DEF_SYSFS) $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS) -DDEFAULT_DEVICE=\"$(ARPING_DEFAULT_DEVICE)\"
LIB_arping = $(LIB_SYSFS) $(LIB_CAP) $(LIB_IDN)

# clockdiff
DEF_clockdiff = $(DEF_CAP)
LIB_clockdiff = $(LIB_CAP)

# ping / ping6
DEF_ping_common = $(DEF_CAP) $(DEF_IDN)
DEF_ping  = $(DEF_CAP) $(DEF_IDN)
LIB_ping  = $(LIB_CAP) $(LIB_IDN)
DEF_ping6 = $(DEF_CAP) $(DEF_IDN) $(DEF_ENABLE_PING6_RTHDR)
LIB_ping6 = $(LIB_CAP) $(LIB_IDN) -lresolv -lcrypto

ping: ping_common.o
ping6: ping_common.o
ping.o ping_common.o: ping_common.h
ping6.o: ping_common.h in6_flowlabel.h

# rarpd
DEF_rarpd =
LIB_rarpd =

# rdisc
DEF_rdisc = $(DEF_ENABLE_RDISC_SERVER)
LIB_rdisc =

# tracepath
DEF_tracepath = $(DEF_IDN)
LIB_tracepath = $(LIB_IDN)

# tracepath6
DEF_tracepath6 = $(DEF_IDN)
LIB_tracepath6 =

# traceroute6
DEF_traceroute6 = $(DEF_CAP) $(DEF_IDN)
LIB_traceroute6 = $(LIB_CAP) $(LIB_IDN)

# tftpd
DEF_tftpd =
DEF_tftpsubs =
LIB_tftpd =

tftpd: tftpsubs.o
tftpd.o tftpsubs.o: tftp.h

# -------------------------------------
# ninfod
ninfod:
	@set -e; \
		if [ ! -f ninfod/Makefile ]; then \
			cd ninfod; \
			./configure; \
			cd ..; \
		fi; \
		$(MAKE) -C ninfod

# -------------------------------------
# modules / check-kernel are only for ancient kernels; obsolete
check-kernel:
ifeq ($(KERNEL_INCLUDE),)
	@echo "Please, set correct KERNEL_INCLUDE"; false
else
	@set -e; \
	if [ ! -r $(KERNEL_INCLUDE)/linux/autoconf.h ]; then \
		echo "Please, set correct KERNEL_INCLUDE"; false; fi
endif

modules: check-kernel
	$(MAKE) KERNEL_INCLUDE=$(KERNEL_INCLUDE) -C Modules

# -------------------------------------
man:
	$(MAKE) -C doc man

html:
	$(MAKE) -C doc html

clean:
	@rm -f *.o $(TARGETS)
	@$(MAKE) -C Modules clean
	@$(MAKE) -C doc clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod clean; \
		fi

distclean: clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod distclean; \
		fi

# -------------------------------------
snapshot:
	@if [ "`uname -n`" != "pleiades" ]; then echo "Not authorized to advance snapshot"; exit 1; fi
	@date "+[$(TAG)]" > RELNOTES.NEW
	@echo >>RELNOTES.NEW
	@git log --no-merges $(LASTTAG).. | git shortlog >> RELNOTES.NEW
	@echo >> RELNOTES.NEW
	@cat RELNOTES >> RELNOTES.NEW
	@mv RELNOTES.NEW RELNOTES
	@date "+static char SNAPSHOT[] = \"$(TAG)\";" > SNAPSHOT.h
	@$(MAKE) -C doc snapshot
	@$(MAKE) man
	@git commit -a -m "iputils-$(TAG)"
	@git tag -s -m "iputils-$(TAG)" $(TAG)
	@git archive --format=tar --prefix=iputils-$(TAG)/ $(TAG) | bzip2 -9 > ../iputils-$(TAG).tar.bz2
