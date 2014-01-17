
start:
	li	r2,0x20
	jmpl	r4,print
	ba	start

print:
	li	r3,0x50
	jmpl	r5,outchar
	br	r4

outchar:
	out	r3,0(r2)
loop:
	in	r3,1(r2)
	andi	r3,1
	bne	loop
	br	r5
