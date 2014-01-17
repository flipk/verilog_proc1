
start:
	li	r15,1024
	
loader:
	li	r10,0x20   # rs232 port
printrdystring:	
	mr	r0,r10
	li	r1,readyString
	jmpl	r14,print
readNextChar:	
	mr	r0,r10   # port
	li	r1,1     # wait
	jmpl	r14,readChar
	cmpi	r6,13   # carriage return
	beq	printrdystring
	cmpi	r6,10   # newline
	beq	printrdystring
	cmpi	r6,0x41 # 'A'
	beq	gotA
	ba	readNextChar

gotA:
	mr	r0,r10
	li	r1,receivedAString
	jmpl	r14,print
	ba	printrdystring

readyString:
	asciiz	"\r\nReady\r\n>"
receivedAString:
	asciiz  "Got an 'A'\r\n"

	# void print(rs232port *, char *str)

print:
	# this function needs stack space for r10, r11, retaddr
	subi	r15,6
	st	r10,0(r15)
	st	r11,2(r15)
	st	r14,4(r15)
	mr	r10,r0
	mr	r11,r1
printNextChar:	
	ldb	r1,0(r11)  # get next print byte
	addi	r11,1
	cmpi	r1,0       # check for nul
	beq	printDone  # if nul, return
	mr	r0,r10
	jmpl	r14,writeChar  # output one char
	ba	printNextChar      # go round for next char
printDone:
	ld	r10,0(r15)
	ld	r11,2(r15)
	ld	r14,4(r15)
	addi	r15,6
	br	r14        # return to caller

	# r1 is rs232 port
	# r3 is char to tx
	# r5 is clobbered
	# r14 is return address

	# void writeChar(rs232port *, uint8_t byte)

writeChar:
	in	r6,1(r0)   # read tx status
	andi	r6,1       # check 'tx_busy'
	bne	writeChar  # if set, poll again
	out	r1,0(r0)   # tx char
	br	r14        # return to caller

	# uint8_t readChar(rs232port *, bool wait)
	# if wait==0, returns 0 if no char available
	# if wait==1, doesn't return until char is available
	
readChar:
	in	r6,3(r0)  # read rx status
	andi	r6,1      # check 'rx_ready'
	bne	charReady # if not zero, a byte is ready
	cmpi	r1,0
	bne	readChar  # caller wants us to wait
	li	r6,0
	br	r14       # return 0
charReady:	
	in	r6,2(r0)  # read 'rx_data'
	br	r14       # return to caller
