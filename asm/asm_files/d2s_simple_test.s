// test of DRAM
// 0: 0000ffff
// 4: 0
// 8: 1

lui $4, 32768 // 0x8000_0000, led base.
addi $5, $0, 1 // to turn on LED, $5 is always 1.


d2s $0, $0, 4
ori $1, $0, 65535 

lw $2, $0, 0 // addr 0x0010
beq $1, $2, 1 // goto success.
j 8   // goto 0x0020, skip success.
sw   $5, $4, 0 // success. 

lw $2, $0, 4 // addr 0x0020
addi $1, $0, 0 

beq $1, $2, 1
j 13  // goto 0x34  
sw $5, $4, 4 // addr: 0x0030

lw $2, $0, 8
addi $1, $0, 1

beq $1, $2, 1   
j 18  // goto 0x48, addr: 0x0040
sw $5, $4, 8

halt