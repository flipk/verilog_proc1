
start:
	li	r4,print
	brl	r4
	ba	start

print:
	li	r3,0x50
	li	r5,outchar
	brl	r5
	brl	r4

outchar:
	li	r2,0x20
	out	r3,0(r2)
loop:
	in	r3,1(r2)
	andi	r3,1
	bne	loop
	brl	r5
