// 0x0000 1
// 0x0004 1
// 0x0008 46
// 0x000C 1

addi $3, $0, 0 // store result to $3.

addi $2, $0, 2 // target, core 2.


beq $2, $31, 1
j 11 // goto 0x2c

// 0x0010
// only exexure core 2. add 1 to 9. result is in $3.
addi $1, $0, 1
addi $4, $0, 10 // loop begin

add $3, $3, $1
addi $1, $1, 1

// 0x0020
slt $5, $4, $1
beq $5, $0, -5 // goback if $1 != 10
j 12 // goto 0x0030

addi $3, $0, 1 // 0x002c, jump from above.
// 0x0030, exec both
muli $1, $31, 4
sw $3, $1, 0
halt
