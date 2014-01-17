
memorytop equ 0x2000

start:
	li	r5,0x00
	in	r6,1(r5)
	li	r10,0x28

	cmpi	r6,2
	beq	cpu2

cpu1:	
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	li	r0,1
	out	r0,0(r10)
wait1:
	in	r4,0(r10)
	cmpi	r4,0
	beq	wait1

	ba	self

cpu2:	
	in	r11,0(r10)
	cmpi	r11,0
	beq	cpu2

	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2
	li	r0,2

	addi	r11,1
	out	r11,0(r10)
	
self:
	ba	self
	
