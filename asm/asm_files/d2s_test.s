// assume in DDR,
// 24: 123
// 28: 456
// 32: 789
// 34: 5555

lui $4, 32768 // 0x8000_0000, led base.
addi $5, $0, 1 // to turn on LED, $5 is always 1.
addi $1, $0, 12 // SRAM base address, 12.
addi $2, $0, 24
d2s $1, $2, 4 // addr: 0x0010

addi $1, $0, 0

lw $2, $0, 12
add $1, $1, $2

lw $2, $0, 16 // addr: 0x0020
add $1, $1, $2

lw $2, $0, 20
add $1, $1, $2

lw $2, $0, 24 // addr: 0x0030
add $1, $1, $2

addi $3, $0, 6923 

beq $1, $3, 3 // goto success.


// fail. turn on led[0], led[2]
sw   $5, $4, 0  // addr: 0x0040
sw   $5, $4, 8

j 104  // jump to 0x0000_0058, halt

// success, turn on three led.
sw   $5, $4, 0
sw   $5, $4, 4 // addr: 0x0050
sw   $5, $4, 8

halt // 0x0000_0058
