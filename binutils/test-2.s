
start:
	li	r1,-1
	lib	r1,0xff04
	lib	r1,5
	li	r2,0x100
	or	r2,r1
	ori	r2,0x1000
	li	r3,0x0ff0
	and	r2,r3
	li	r4,0x160
	li	r5,0x3c0
	add	r4,r5
	li	r4,0x160
	li	r5,0x3c0
	addb	r4,r5        # this should set C
	andi	r4,0         # this should clear C, set Z
	li	r4,0x160
	addbi	r4,0x3c0     # this should set C
	li	r4,0x4567
	li	r5,0x1234
	sub	r4,r5   # this should be 4567-1234, should clear C
	li	r4,0x4567
	li	r5,0x1234
	subb	r4,r5   # this should be 67-34 should clear C
	li	r4,0x1234
	li	r5,0x4567
	subb	r4,r5   # this should be 34-67 should set C
	li	r8,1
	roli	r8,5
	roli	r8,5
	roli	r8,5
	roli	r8,5
	li	r9,7
	rol	r8,r9
	rol	r8,r9
	rol	r8,r9
	rol	r8,r9
	rol	r8,r9
	li	r8,0x105
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	rolbi	r8,1
	li	r6,0x104
	li	r7,0x204
	cmpb	r6,r7   # should set Z
	cmp	r6,r7   # should set C
	neg	r6
	negb	r7
	xori	r6,0x55
	xor	r6,r7
	xor	r6,r6
self:
	ba	self
