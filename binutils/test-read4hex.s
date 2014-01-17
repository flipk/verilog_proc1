start:
	li	r15,0x400
	jmpl	r14,read1HexDigit
self:
	ba	self



read1HexDigit:	# uint16_t read1HexDigit(void)
	subi	r15,8       # need 8 bytes on the stack
	st	r10,0(r15)
	st	r14,2(r15)
	st	r11,4(r15)

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
	subbi	r6,87
	mr	r10,r6
	jmpl	r14,writeChar
	mr	r6,r10
	ba	read1HexDone
isUpperAlpha:
	subbi	r6,55
	mr	r10,r6
	jmpl	r14,writeChar
	mr	r6,r10
	ba	read1HexDone
isDigit:
	subbi	r6,0x30
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
	addi	r15,8
	br	r14        # return 1 hex digit




	# if wait==0, returns 0 if no char available
	# if wait==1, doesn't return until char is available
readChar: # uint8_t readChar(bool wait)
	li	r6,0x31
	br	r14       # return to caller



writeChar: # void writeChar(uint8_t byte)
	li	r1,0x20    # serial port addr
	in	r6,1(r1)   # read tx status
	andi	r6,1       # check 'tx_busy'
	bne	writeChar  # if set, poll again
	out	r0,0(r1)   # tx char
	br	r14        # return to caller
