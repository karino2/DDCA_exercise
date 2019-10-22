// result:
// 0000: 16
// 0004: 5
// 0008: 16
// 000C: 13

// first group, 0, 2 core.
// second group 1, 3 core.
// First group is $2==0, Second group is $2==1.
addi $2, $0, 0

addi $1, $0, 1
beq $1, $31, 3
addi $1, $0, 3
// addr: 0x0010
beq $1, $31, 1
j 7 // goto 0x1C
addi $2, $0, 1 // only execute second group

addi $1, $0, 0
// addr: 0x0020
beq $1, $2, 4
// second group only, core 1, 3.
// calculate $3= 1+$31*4
addi $3, $0, 1
muli $4, $31, 4
add $3, $3, $4
// addr: 0x0030
j 18 // goto 0x48

// first group, core 0, 2
addi $3, $0, 1
add $3, $3, $3
add $3, $3, $3
// addr: 0x0040
add $3, $3, $3
add $3, $3, $3

// exec both.
muli $4, $31, 4
sw $3, $4, 0

halt
