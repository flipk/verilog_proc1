ARCH = `$(HOME)/pfk/bin/architecture`
noinst_PROGRAMS = pfk_proc1_as pfk_proc1_sim

CC = gcc
CFLAGS = 
CXX = g++
CXXFLAGS = 
CPPFLAGS = -I$(srcdir)
AR = ar
LEX = flex
YACC = bison
LFLAGS = 
YFLAGS = 
pfk_proc1_as_CC = $(CC)
pfk_proc1_as_CXX = $(CXX)
pfk_proc1_as_LDFLAGS = -Wl,-rpath -Wl,/home/flipk/pfk/$(ARCH)/lib -L$(HOME)/pfk/$(ARCH)/lib -lpfkdll2
pfk_proc1_as_CXXFLAGS = -g3 -Wall
pfk_proc1_as_CPPFLAGS = -I$(HOME)/pfk/include/dll2
pfk_proc1_sim_CC = $(CC)
pfk_proc1_sim_CXX = $(CXX)
pfk_proc1_sim_LDFLAGS = -Wl,-rpath -Wl,/home/flipk/pfk/$(ARCH)/lib -L$(HOME)/pfk/$(ARCH)/lib -lpfkdll2
pfk_proc1_sim_CXXFLAGS = -g3 -Wall
pfk_proc1_sim_CPPFLAGS = -I$(HOME)/pfk/include/dll2
srcdir = /home/flipk/proj/proc/binutils
builddir = /home/flipk/proj/proc/binutils

all: xmakefile
	+make $(MAKEJOBS) -f xmakefile pfk_proc1_as pfk_proc1_sim

xmakefile: Makefile pfk_proc1_as-parser.d pfk_proc1_as-tokenizer.d pfk_proc1_as-parse_actions.d pfk_proc1_as-output_file.d pfk_proc1_as-as_main.d pfk_proc1_sim-sim.d pfk_proc1_sim-sim_main.d
	rm -f xmakefile xmakefile-tmp
	cat Makefile > xmakefile-tmp
	echo '' >> xmakefile-tmp
	cat pfk_proc1_as-parser.d pfk_proc1_as-tokenizer.d pfk_proc1_as-parse_actions.d pfk_proc1_as-output_file.d pfk_proc1_as-as_main.d pfk_proc1_sim-sim.d pfk_proc1_sim-sim_main.d >> xmakefile-tmp
	mv xmakefile-tmp xmakefile

Makefile: /home/flipk/proj/proc/binutils/Makefile.am
	ampfk /home/flipk/proj/proc/binutils/Makefile.am
	make clean

pfk_proc1_as-parser.d: pfk_proc1_as-parser.cc
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -MT ' pfk_proc1_as-parser.o pfk_proc1_as-parser.d ' -M -MF pfk_proc1_as-parser.d pfk_proc1_as-parser.cc

pfk_proc1_as-tokenizer.d: pfk_proc1_as-tokenizer.cc
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -MT ' pfk_proc1_as-tokenizer.o pfk_proc1_as-tokenizer.d ' -M -MF pfk_proc1_as-tokenizer.d pfk_proc1_as-tokenizer.cc

pfk_proc1_as-parse_actions.d: $(srcdir)/parse_actions.C
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -MT ' pfk_proc1_as-parse_actions.o pfk_proc1_as-parse_actions.d ' -M -MF pfk_proc1_as-parse_actions.d $(srcdir)/parse_actions.C

pfk_proc1_as-output_file.d: $(srcdir)/output_file.C
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -MT ' pfk_proc1_as-output_file.o pfk_proc1_as-output_file.d ' -M -MF pfk_proc1_as-output_file.d $(srcdir)/output_file.C

pfk_proc1_as-as_main.d: $(srcdir)/as_main.C
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -MT ' pfk_proc1_as-as_main.o pfk_proc1_as-as_main.d ' -M -MF pfk_proc1_as-as_main.d $(srcdir)/as_main.C

pfk_proc1_sim-sim.d: $(srcdir)/sim.C
	$(pfk_proc1_sim_CXX) $(CXXFLAGS) $(pfk_proc1_sim_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_sim_CPPFLAGS) -MT ' pfk_proc1_sim-sim.o pfk_proc1_sim-sim.d ' -M -MF pfk_proc1_sim-sim.d $(srcdir)/sim.C

pfk_proc1_sim-sim_main.d: $(srcdir)/sim_main.C
	$(pfk_proc1_sim_CXX) $(CXXFLAGS) $(pfk_proc1_sim_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_sim_CPPFLAGS) -MT ' pfk_proc1_sim-sim_main.o pfk_proc1_sim-sim_main.d ' -M -MF pfk_proc1_sim-sim_main.d $(srcdir)/sim_main.C

pfk_proc1_as: pfk_proc1_as-parser.o pfk_proc1_as-tokenizer.o pfk_proc1_as-parse_actions.o pfk_proc1_as-output_file.o pfk_proc1_as-as_main.o $(pfk_proc1_as_LDADD)
	rm -f pfk_proc1_as
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) -o pfk_proc1_as  pfk_proc1_as-parser.o pfk_proc1_as-tokenizer.o pfk_proc1_as-parse_actions.o pfk_proc1_as-output_file.o pfk_proc1_as-as_main.o $(pfk_proc1_as_LDADD) $(pfk_proc1_as_LDFLAGS)

pfk_proc1_sim: pfk_proc1_sim-sim.o pfk_proc1_sim-sim_main.o $(pfk_proc1_sim_LDADD)
	rm -f pfk_proc1_sim
	$(pfk_proc1_sim_CXX) $(CXXFLAGS) $(pfk_proc1_sim_CXXFLAGS) -o pfk_proc1_sim  pfk_proc1_sim-sim.o pfk_proc1_sim-sim_main.o $(pfk_proc1_sim_LDADD) $(pfk_proc1_sim_LDFLAGS)

pfk_proc1_as-parser.o: pfk_proc1_as-parser.cc
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -c pfk_proc1_as-parser.cc -o pfk_proc1_as-parser.o

pfk_proc1_as-tokenizer.o: pfk_proc1_as-tokenizer.cc
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -c pfk_proc1_as-tokenizer.cc -o pfk_proc1_as-tokenizer.o

pfk_proc1_as-parse_actions.o: $(srcdir)/parse_actions.C
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -c $(srcdir)/parse_actions.C -o pfk_proc1_as-parse_actions.o

pfk_proc1_as-output_file.o: $(srcdir)/output_file.C
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -c $(srcdir)/output_file.C -o pfk_proc1_as-output_file.o

pfk_proc1_as-as_main.o: $(srcdir)/as_main.C
	$(pfk_proc1_as_CXX) $(CXXFLAGS) $(pfk_proc1_as_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_as_CPPFLAGS) -c $(srcdir)/as_main.C -o pfk_proc1_as-as_main.o

pfk_proc1_sim-sim.o: $(srcdir)/sim.C
	$(pfk_proc1_sim_CXX) $(CXXFLAGS) $(pfk_proc1_sim_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_sim_CPPFLAGS) -c $(srcdir)/sim.C -o pfk_proc1_sim-sim.o

pfk_proc1_sim-sim_main.o: $(srcdir)/sim_main.C
	$(pfk_proc1_sim_CXX) $(CXXFLAGS) $(pfk_proc1_sim_CXXFLAGS) $(CPPFLAGS) $(pfk_proc1_sim_CPPFLAGS) -c $(srcdir)/sim_main.C -o pfk_proc1_sim-sim_main.o

pfk_proc1_as-parser.cc parser.h: $(srcdir)/parser.Y
	rm -f pfk_proc1_as-parser.cc parser.h
	$(YACC) $(pfk_proc1_as_YFLAGS) -d $(srcdir)/parser.Y
	mv parser.tab.C pfk_proc1_as-parser.cc
	mv parser.tab.H parser.h

pfk_proc1_as-tokenizer.cc: $(srcdir)/tokenizer.L
	rm -f pfk_proc1_as-tokenizer.cc
	$(LEX) $(pfk_proc1_as_LFLAGS) $(srcdir)/tokenizer.L
	mv lex.yy.c pfk_proc1_as-tokenizer.cc

clean: 
	rm -f xmakefile *.d *.o pfk_proc1_as pfk_proc1_as-parser.cc parser.h pfk_proc1_as-tokenizer.cc pfk_proc1_sim

