// test of DRAM
// 0: 0000ffff
// 4: 0
// 8: 1

lui $4, 32768 // 0x8000_0000, led base.
addi $5, $0, 1 // to turn on LED, $5 is always 1.


d2s $0, $0, 4
ori $1, $0, 65535 

// addr 0x0010
lw $2, $0, 0
beq $1, $2, 1 // goto success.
j 8   // goto 0x0020, skip success.
sw   $5, $4, 0 // success. 

// 0x0020
sw $2, $0, 16 

lw $2, $0, 4
addi $1, $0, 0 

beq $1, $2, 1

// 0x0030
j 14  // goto 0x38
sw $5, $4, 4

sw $2, $0, 20


lw $2, $0, 8
// 0x0040
addi $1, $0, 1

beq $1, $2, 1   
j 20  // goto 0x50
sw $5, $4, 8

// 0x0050
sw $2, $0, 24
addi $1, $0, 16
s2d $1, $1, 4

halt