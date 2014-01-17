
memorytop equ 0x2000
gapsize equ 0x1938
perfCounterIO equ 0x30
rs232IO equ 0x20
cpuidIO equ 0x01
procverIO equ 0x00	
dropboxIO equ 0x28
w1a0out equ 0x56

start:
	li	r15,stackTop
	jmp	loader

	space	gapsize
stackTop:

versionString:
	asciiz  "\r\n\r\nPFK_PROC_1 bootloader version 0.3 "
cpuidString:	
	asciiz  " CPUID 0x"
procverString:
	asciiz  " PROCVER 0x"
qforhelpString:
	asciiz "\r\n   '?' for help\r\n"
prompt:
	asciiz	"\r\n% "
helpString:
	ascii	"?\r\n"
	ascii	" ? - help (this message)\r\n"
	ascii	" V - display version header\r\n"
	ascii	" D - display memory\r\n"
	ascii   " P - show performance counter\r\n"
	ascii	" L - load S-records\r\n"
	ascii   " 2 - read dropbox from CPU 2\r\n"
	ascii   " 0 - turn of w1a0\r\n"
	ascii   " 1 - turn on w1a0\r\n"
	ascii	" J - jump to S-record entry point\r\n"
	byte	0

dropbox2String:
	asciiz  "2\r\nDropbox 2: "

	# S9 carries an entry point address which gets stored here
entryPoint:
	word	0xFFFF

print:	globl	# void print(char *str)
	subi	r15,4           # stack space for r10, retaddr
	st	r10,0(r15)
	st	r14,2(r15)
	mr	r10,r0
printNextChar:	
	ldb	r0,0(r10)  # get next print byte
	addi	r10,1
	cmpi	r0,0       # check for nul
	beq	printDone  # if nul, return
	jmpl	r14,writeChar  # output one char
	ba	printNextChar      # go round for next char
printDone:
	ld	r10,0(r15)
	ld	r14,2(r15)
	addi	r15,4
	br	r14        # return to caller

writeChar: globl # void writeChar(uint8_t byte)
	li	r1,rs232IO    # serial port addr
	in	r6,1(r1)   # read tx status
	andi	r6,1       # check 'tx_busy'
	bne	writeChar  # if set, poll again
	out	r0,0(r1)   # tx char
	br	r14        # return to caller
	
	# if wait==0, returns 0 if no char available
	# if wait==1, doesn't return until char is available
readChar: globl # uint8_t readChar(bool wait)
	li	r1,rs232IO    # serial port addr
	in	r6,3(r1)  # read rx status
	andi	r6,1      # check 'rx_ready'
	bne	charReady # if not zero, a byte is ready
	cmpi	r0,0
	bne	readChar  # caller wants us to wait
	li	r6,0
	br	r14       # return 0
charReady:	
	in	r6,2(r1)  # read 'rx_data'
	br	r14       # return to caller

read1HexDigit:	globl # uint16_t read1HexDigit(bool echo)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r14,2(r15)
	st	r11,4(r15)
	st	r12,6(r15)

	mr	r12,r0   # echo flag

	li	r0,1
	jmpl	r14,readChar
	mr	r0,r6
	cmpbi	r6,0x30
	blt	badHexDigit # less than '0'
	cmpbi	r6,0x39
	ble	isDigit
	cmpbi	r6,0x41
	blt	badHexDigit # less than 'A'
	cmpbi	r6,0x46
	ble	isUpperAlpha
	cmpbi	r6,0x61
	blt	badHexDigit # less than 'a'
	cmpbi	r6,0x66
	bgt	badHexDigit # greater than 'f'
isLowerAlpha:
	subbi	r6,87   # turn lowercase into hex
	ba	goodHexDigit
isUpperAlpha:
	subbi	r6,55   # turn uppercase into hex
	ba	goodHexDigit
isDigit:
	subbi	r6,0x30 # turn digit into hex
	ba	goodHexDigit
goodHexDigit:
	cmpi	r12,0   # echo flag
	beq	read1HexDone
	mr	r10,r6
	jmpl	r14,writeChar
	mr	r6,r10
	ba	read1HexDone
badHexDigit:
	li	r6,0xFFFF
read1HexDone:	
	ld	r10,0(r15)
	ld	r14,2(r15)
	ld	r11,4(r15)
	ld	r12,6(r15)
	addi	r15,8
	br	r14        # return 1 hex digit

read2HexDigits:	globl # uint8_t read2HexDigits(bool echo)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r11,2(r15)
	st	r14,4(r15)

	li	r10,0   # digit accumulator
	mr	r11,r0  # echo flag
	ba	readonly2digits

read4HexDigits: globl # uint16_t read4HexDigits(void)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r11,2(r15)
	st	r14,4(r15)

	li	r10,0   # digit accumulator
	mr	r11,r0  # echo flag

#redundant	mr	r0,r11 # echo flag
	jmpl	r14,read1HexDigit
	cmpi	r6,0xFFFF
	beq	badHexDigit2
	roli	r6,12
	or	r10,r6   # first digit

	mr	r0,r11 # echo flag
	jmpl	r14,read1HexDigit
	cmpi	r6,0xFFFF
	beq	badHexDigit2
	roli	r6,8
	or	r10,r6   # second digit

	mr	r0,r11 # echo flag
readonly2digits:	
	jmpl	r14,read1HexDigit
	cmpi	r6,0xFFFF
	beq	badHexDigit2
	roli	r6,4
	or	r10,r6   # third digit

	mr	r0,r11 # echo flag
	jmpl	r14,read1HexDigit
	cmpi	r6,0xFFFF
	beq	badHexDigit2
	or	r10,r6   # fourth digit

	mr	r6,r10   # into return reg

badHexDigit2:	
	ld	r10,0(r15)
	ld	r11,2(r15)
	ld	r14,4(r15)
	addi	r15,8
	br	r14     # return 2 or 4 hex digits

printhexdigit:	globl # void printhexdigit(uint4_t digit)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r14,2(r15)
	cmpi	r0,10
	blt	printdigit1
	addi	r0,55
	ba	printdigit2
printdigit1:
	addi	r0,0x30
printdigit2:	
	jmpl	r14,writeChar
	ld	r10,0(r15)
	ld	r14,2(r15)
	addi	r15,8
	br	r14

printbyte:  globl # void printword(uint8_t word)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r14,2(r15)

	mr	r10,r0
	roli	r0,12
	andi	r0,0xF
	jmpl	r14,printhexdigit

	mr	r0,r10
	andi	r0,0xF
	jmpl	r14,printhexdigit

	ld	r10,0(r15)
	ld	r14,2(r15)
	addi	r15,8
	br	r14

printword:  globl # void printword(uint16_t word)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r14,2(r15)

	mr	r10,r0
	roli	r0,4
	andi	r0,0xF
	jmpl	r14,printhexdigit

	mr	r0,r10
	roli	r0,8
	andi	r0,0xF
	jmpl	r14,printhexdigit

	mr	r0,r10
	roli	r0,12
	andi	r0,0xF
	jmpl	r14,printhexdigit

	mr	r0,r10
	andi	r0,0xF
	jmpl	r14,printhexdigit

	ld	r10,0(r15)
	ld	r14,2(r15)
	addi	r15,8
	br	r14

enablePerfCounter: globl
	li	r0,3
	li	r1,perfCounterIO
	out	r0,0(r1)
	br	r14

printPerfCounter: globl
	subi	r15,4  # ret and r10
	st	r10,0(r15)
	st	r14,2(r15)

	li	r0,0
	li	r10,perfCounterIO
	out	r0,0(r10) # disable perf counter

	in	r0,0(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,1(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,2(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,3(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,4(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,5(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,6(r10) # read a byte
	jmpl	r14,printbyte
	in	r0,7(r10) # read a byte
	jmpl	r14,printbyte

	li	r0,13
	jmpl	r14,writeChar
	li	r0,10
	jmpl	r14,writeChar

	ld	r10,0(r15)
	ld	r14,2(r15)
	addi	r15,4
	br	r14

loader: globl
	li	r10,cpuidIO
	in	r11,0(r10)
	cmpi	r11,1
	beq	loader_cpu1

	li	r10,dropboxIO
	li	r11,0
cpu2_dead:
	out	r11,0(r10)
	addi	r11,1
	ba	cpu2_dead

loader_cpu1:	
	li	r0,1
	li	r1,0x30
	out	r0,0(r1)   # enable perf counter
	li	r0,versionString
	jmpl	r14,print
	li	r0,cpuidString
	jmpl	r14,print
	li	r10,cpuidIO
	in	r0,0(r10)
	jmpl	r14,printbyte
	li	r0,procverString
	jmpl	r14,print
	li	r10,procverIO
	in	r0,0(r10)
	jmpl	r14,printbyte
	li	r0,qforhelpString
	jmpl	r14,print
commandLoop:	
	li	r0,prompt
	jmpl	r14,print
readCommand:	
	li	r0,1
	jmpl	r14,readChar # get a command
	cmpbi	r6,0x56   # 'V'
	bne	checkQuestionMark
	li	r0,0x56
	jmpl	r14,writeChar
	ba	loader
checkQuestionMark:	
	cmpbi	r6,0x3f   # '?'
	beq	printHelpMessage
	cmpbi	r6,0x44   # 'D'
	beq	displayMemory
	cmpbi	r6,0x50   # 'P'
	beq	displayPerfCounterCmd
	cmpbi	r6,0x4C   # 'L'
	beq	loadSrecords
	cmpi	r6,0x4A   # 'J'
	beq	jumpEntryPoint
	cmpi	r6,0x32   # '2'
	beq	readDropbox2
	cmpi	r6,0x30   # '0'
	beq	writeW1A00
	cmpi	r6,0x31   # '1'
	beq	writeW1A01
	cmpbi	r6,13     # carriage return
	beq	commandLoop
	cmpbi	r6,10     # newline
	beq	commandLoop
	ba	readCommand
	
printHelpMessage:
	li	r0,helpString
	jmpl	r14,print
	ba	commandLoop

writeW1A00:
	li	r10,w1a0out
	li	r1,0
	out	r1,0(r10)
	ba	commandLoop
writeW1A01:
	li	r10,w1a0out
	li	r1,1
	out	r1,0(r10)
	ba	commandLoop
readDropbox2:
	li	r0,dropbox2String
	jmpl	r14,print
	li	r10,dropboxIO
	in	r0,0(r10)
	jmpl	r14,printbyte
	ba	commandLoop

displayMemory:
	li	r0,0x44  # 'D'
	jmpl	r14,writeChar
	li	r0,0x20  # ' '
	jmpl	r14,writeChar
	li	r0,1 # echo flag
	jmpl	r14,read4HexDigits
	cmpi	r6,0xFFFF
	beq	commandLoop
	mr	r10,r6
	li	r0,0x0d  # CR
	jmpl	r14,writeChar
	li	r0,0x0a  # NL
	jmpl	r14,writeChar

	li	r11,16  # line count
displayMemoryNextLine:	
	li	r12,8   # word count
	mr	r0,r10
	jmpl	r14,printword	# display address

	li	r0,32
	jmpl	r14,writeChar
	li	r0,0x3A
	jmpl	r14,writeChar
	li	r0,32
	jmpl	r14,writeChar
displayMemoryNextWord:	
	ld	r0,0(r10)
	addi	r10,2
	jmpl	r14,printword

	li	r0,32
	jmpl	r14,writeChar

	subi	r12,1
	bne	displayMemoryNextWord

	li	r0,13
	jmpl	r14,writeChar
	li	r0,10
	jmpl	r14,writeChar

	subi	r11,1
	bne	displayMemoryNextLine

	ba	commandLoop

displayPerfCounterCmd:
	jmpl	r14,printPerfCounter
	jmpl	r14,enablePerfCounter
	ba	commandLoop

loadSrecords:
	mr	r0,r6
	jmpl	r14,writeChar
	li	r0,13
	jmpl	r14,writeChar
	li	r0,10
	jmpl	r14,writeChar
	ba	getNextSRecord

displaySRError:
	li	r0,0x21   # '!'
	ba	displaySRStatus
displaySROK:
	li	r0,0x2E   # '.'
displaySRStatus:
	jmpl	r14,writeChar
	
getNextSRecord:	
	jmpl	r14,readChar
	cmpbi	r6,0x53    # 'S'
	bne	getNextSRecord
	jmpl	r14,readChar
	cmpbi	r6,0x39    # '9' : S9 = end S-record file
	beq	getSREntryPt
	cmpbi	r6,0x31    # '1' : S1 = S-record entry
	bne	getNextSRecord
getS1Length:
	li	r0,0                # echo flag
	jmpl	r14,read2HexDigits  # read length (in words)
	cmpi	r6,0xFFFF
	beq	displaySRError
	mr	r10,r6              # loop counter for words
	li	r0,0                # echo flag
	jmpl	r14,read4HexDigits
	cmpi	r6,0xFFFF
	beq	displaySRError
	mr	r11,r6              # address counter
	mr	r12,r11             # checksum (includes address field)
getNextSRByte:
	li	r0,0                # echo flag
	jmpl	r14,read4HexDigits  # read next unit of data
	# at this point, FFFF is a valid thing to read,
	# so we actually can't detect a hex char error here.
	# but that's okay because we can detect a checksum err.
	# at the end.
	st	r6,0(r11)
	add	r12,r6   # add to checksum
	addi	r11,2    # increment address counter
	subi	r10,1    # decrement word counter
	bne	getNextSRByte
	li	r0,0 # echo flag
	jmpl	r14,read4HexDigits  # read checksum
	cmp	r6,r12
	bne	displaySRError
	ba	displaySROK

getSREntryPt:
	li	r0,0                # echo flag
	jmpl	r14,read4HexDigits  # read entry point
	mr	r12,r6              # save entry point
	li	r0,0                # echo flag
	jmpl	r14,read4HexDigits  # read entry point checksum
	cmp	r12,r6
	bne	badS9Entry
	li	r11,entryPoint
	st	r12,0(r11)
	li	r0,0x2E   # '.'
	jmpl	r14,writeChar
	ba	commandLoop

badS9Entry:	
	li	r0,0x21   # '!'
	jmpl	r14,writeChar
	
	ba	commandLoop

jumpEntryPoint:
	li	r10,entryPoint
	ld	r11,0(r10)
	cmpi	r11,0xFFFF
	beq	commandLoop
	br	r11
