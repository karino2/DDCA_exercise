// result:
// 0000: 7
// 0004: 2
// 0008: 7
// 000C: 7

addi $2, $0, 1 // target core
muli $3, $31, 4 // target address.

addi $1, $0, 0
beq $2, $31, 1
addi $1, $1, 5  // only 0,  2, 3 core execute this line.
addi $1, $1, 2
sw $1, $3, 0
halt
