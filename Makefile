# st - simple terminal
# See LICENSE file for copyright and license details.
.POSIX:

include config.mk

SRC = st.c x.c
OBJ = $(SRC:.c=.o)

# st + dvtm multicall 单文件:argv[0] 为 dvtm 时运行内嵌的 dvtm
NCURSES_DIR = deps/ncurses/ncurses-6.4
NCURSES_TAR = deps/ncurses/ncurses-6.4.tar.gz
NCURSES_LIB = $(NCURSES_DIR)/lib/libncursesw.a

DVTMFLAGS = -std=c99 -Ideps/dvtm -I$(NCURSES_DIR)/include -DNDEBUG \
	-D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -D_XOPEN_SOURCE_EXTENDED \
	-DVERSION=\"0.15-stfork\"

all: st

# 静态 ncursesw,--with-fallbacks=st-256color 把 terminfo 编进库(零文件落地)
$(NCURSES_DIR)/.configured: $(NCURSES_TAR)
	tar -xzf $(NCURSES_TAR) -C deps/ncurses
	cd $(NCURSES_DIR) && ./configure --enable-widec --without-shared \
		--with-normal --without-debug --without-ada --without-cxx-binding \
		--without-tests --without-manpages --disable-db-install \
		--with-fallbacks="st-256color"
	touch $@

$(NCURSES_LIB): $(NCURSES_DIR)/.configured
	$(MAKE) -C $(NCURSES_DIR) libs

deps/dvtm/config.h: deps/dvtm/config.def.h
	cp deps/dvtm/config.def.h $@

dvtm.o: deps/dvtm/dvtm.c deps/dvtm/config.h $(NCURSES_LIB)
	$(CC) $(CFLAGS) $(DVTMFLAGS) -c -o $@ $<

vt.o: deps/dvtm/vt.c deps/dvtm/config.h $(NCURSES_LIB)
	$(CC) $(CFLAGS) $(DVTMFLAGS) -c -o $@ $<

dispatch.o: dispatch.c
	$(CC) $(CFLAGS) -c -o $@ $<

config.h:
	cp config.def.h config.h

.c.o:
	$(CC) $(STCFLAGS) -c $<

st.o: config.h st.h win.h
x.o: arg.h config.h st.h win.h

$(OBJ): config.h config.mk

st: $(OBJ) dispatch.o dvtm.o vt.o
	$(CC) -o $@ $(OBJ) dispatch.o dvtm.o vt.o $(NCURSES_LIB) $(STLDFLAGS)

clean:
	rm -f st $(OBJ) dispatch.o dvtm.o vt.o st-$(VERSION).tar.gz
	rm -rf $(NCURSES_DIR)

dist: clean
	mkdir -p st-$(VERSION)
	cp -R FAQ LEGACY TODO LICENSE Makefile README config.mk\
		config.def.h st.info st.1 arg.h st.h win.h $(SRC)\
		st-$(VERSION)
	tar -cf - st-$(VERSION) | gzip > st-$(VERSION).tar.gz
	rm -rf st-$(VERSION)

install: st
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f st $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/st
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	sed "s/VERSION/$(VERSION)/g" < st.1 > $(DESTDIR)$(MANPREFIX)/man1/st.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/st.1
	tic -sx st.info
	@echo Please see the README file regarding the terminfo entry of st.

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/st
	rm -f $(DESTDIR)$(MANPREFIX)/man1/st.1

.PHONY: all deps clean dist install uninstall
