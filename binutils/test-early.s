this program prints out 'Hello there'

0000: 8801 0020    li r1,0x20
0004: 8802 0030    li r2,bufferaddress
0008: 9c23 0000    nextchar: ldb r3,0(r2)
000c: 3802 0001    addi r2,0x01
0010: 6c03 0000    cmpi r3,0x00
0014: e801 0014    beq done
0018: c813 0000    out r3,0(r1)
001c: b813 0001    poll: in  r3,1(r1)
0020: 1803 0001    andi r3,0x01
0024: e802 fff4    bne poll
0028: e800 ffdc    ba nextchar
002c: e800 fffc    done: ba done
0030: 4865 6c6c 6f20 7468 6572 650d 0a00

8801
0020
8802
0030
9c23
0000
3802
0001
6c03
0000
e801
0014
c813
0000
b813
0001
1803
0001
e802
fff4
e800
ffdc
f800
0000
4865
6c6c
6f20
7468
6572
650d
0a00
0000

this program tests 'stb' and 'ldb' followed by one-word instruction.

8802 0020   li r2,0x40
8803 0001   li r3,0x01
8804 0001   li r4,0x01
ac23 0000   stb r3,0(r2)
3042        add r2,r4
3043        add r3,r4
ac23 0000   stb r3,0(r2)
3043        add r3,r4
3042        add r2,r4
4802 0002   subi r2,2
9c25 0000   ldb r5,0(r2)
3045        add r5,r4
3042        add r2,r4
9c25 0000   ldb r5,0(r2)
3042        add r2,r4
3045        add r5,r4
e800 fffc   ba self

8802
0020
8803
0001
8804
0001
ac23
0000
3042
3043
ac23
0000
3043
3042
4802
0002
9c25
0000
3045
3042
9c25
0000
3042
3045
e800
fffc

this program reads one byte of data from the rs232 port.

8802 0020   li r2,0x20
8803 0050   li r3,0x50
c823 0000   out r3,0(r2)
b823 0003   wait: in r3,3(r2)
1803 0001   andi r3,1
e801 fff4   beq wait
b823 0002   in r3,2(r2)
c823 0000   out r3,0(r2)
e800 ffe8   ba wait

8802
0020
8803
0050
c823
0000
b823
0003
1803
0001
e801
fff4
b823
0002
c823
0000
e800
ffe8
