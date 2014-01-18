
DESTDIR= /auto/gliese_d/projects/proc1/

all: 
	echo nothing to do

copy:
	@cp binutils/bootloader.hex .
	@for f in *.v *.ucf *.hex ; do \
		cmp -s $$f $(DESTDIR)/$$f || ( \
			cp $$f $(DESTDIR)/$$f ; \
			echo copying $$f ) ; \
	done

touch:
	files=`echo *.v *.ucf *.hex` ; \
		cd $(DESTDIR) ; \
		touch $$files

load:
	sudo ./papilio-prog -f top.bit
