addi $2, $0, 5
addi $3, $0, 12
addi $7, $3, -9
or $4, $7, $2
and $5, $3, $4
add $5, $5, $4
beq $5, $7, 10 // goto end
slt $4, $3, $4
beq $4, $0, 1 // goto arond
addi $5, $0, 0
slt $4, $7, $2 // :around, address 0x28
add $7, $4, $5
sub $7, $7, $2
sw $7, $3, 68
lw $2, $0, 80
j 17 // goto end
addi $2, $0, 1
sw $2, $0, 84 // :end, address 0x44