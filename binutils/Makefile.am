
CC=gcc
CFLAGS=
CXX=g++
CXXFLAGS=
CPPFLAGS= 
AR=ar
LEX=flex
YACC=yacc
LFLAGS=
YFLAGS=
ARCH= `$(HOME)/pfk/bin/architecture`

noinst_PROGRAMS = pfk_proc1_as pfk_proc1_sim

pfk_proc1_as_SOURCES = parser.Y tokenizer.L parse_actions.C output_file.C \
	as_main.C
pfk_proc1_as_HEADERS =          tokenizer.H parse_actions.H output_file.H
pfk_proc1_as_CPPFLAGS = -I$(HOME)/pfk/include/dll2
pfk_proc1_as_CXXFLAGS = -g3 -Wall
pfk_proc1_as_LDFLAGS = \
	-Wl,-rpath -Wl,/home/flipk/pfk/$(ARCH)/lib \
	-L$(HOME)/pfk/$(ARCH)/lib -lpfkdll2


pfk_proc1_sim_SOURCES = sim.C sim_main.C
pfk_proc1_sim_HEADERS =
pfk_proc1_sim_CPPFLAGS = -I$(HOME)/pfk/include/dll2
pfk_proc1_sim_CXXFLAGS = -g3 -Wall
pfk_proc1_sim_LDFLAGS = \
	-Wl,-rpath -Wl,/home/flipk/pfk/$(ARCH)/lib \
	-L$(HOME)/pfk/$(ARCH)/lib -lpfkdll2
