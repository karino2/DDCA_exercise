addi $1, $0, 3
addi $2, $0, 5
addi $3, $0, 5
addi $4, $0, 0
beq $1, $2, 1
addi $4, $0, 6 // should not skip
addi $5, $0, 7
beq $2, $3, 1
addi $5, $0, 99 // should skip
addi $6, $0, 3