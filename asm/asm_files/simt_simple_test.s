// 0x0000: 3
// 0x0004: 7
// 0x0008: 11
// 0x000C: 15
muli $1, $31, 4  // $1 = 0, 4, 8, 12
addi $2, $1, 3   // $2 = 3, 7, 11, 15
sw $2, $1, 0
halt