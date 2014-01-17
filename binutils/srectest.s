memorytop equ 0x2000
gapsize equ 0x1a30
perfCounterIO equ 0x30
rs232IO equ 0x20
print equ 0x1b2c
writeChar equ 0x1b60
readChar equ 0x1b76
read1HexDigit equ 0x1b9a
read2HexDigits equ 0x1c30
read4HexDigits equ 0x1c4a
printhexdigit equ 0x1cbe
printbyte equ 0x1cf0
printword equ 0x1d22
enablePerfCounter equ 0x1d70
printPerfCounter equ 0x1d7e
loader equ 0x1df4

	org	0x10
entry:	
	jmpl	r14,printPerfCounter
	jmpl	r14,enablePerfCounter

	li	r10,0
loop:	
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	or	r1,r2
	subi	r10,1
	bne	loop

	jmpl	r14,printPerfCounter
	jmpl	r14,enablePerfCounter

	jmp	loader
