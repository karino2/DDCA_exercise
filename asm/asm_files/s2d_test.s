// just send data to dram
// 0018 123
// 001C 456
// 0020 789
// 0024 5555

addi $1, $0, 123
sw $1, $0, 24
addi $1, $0, 456
sw $1, $0, 28
addi $1, $0, 789
sw $1, $0, 32
addi $1, $0, 5555
sw $1, $0, 36
addi $1, $0, 24
addi $2, $0, 24

s2d $1, $2, 4
halt