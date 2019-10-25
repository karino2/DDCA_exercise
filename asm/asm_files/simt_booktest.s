beq $0, $31, 1
j halt  // execute only core0. other core goto halt.

addi $2, $0, 5
addi $3, $0, 12
addi $7, $3, -9
or $4, $7, $2
and $5, $3, $4
add $5, $5, $4
beq $5, $7, 11 // goto end
slt $4, $3, $4
beq $4, $0, 1 // goto arond
addi $5, $0, 0
slt $4, $7, $2 // :around
add $7, $4, $5
sub $7, $7, $2
sw $7, $3, 68
nop
lw $2, $0, 80
j end
addi $2, $0, 1 // shouldn't happen
end:
sw $2, $0, 84
halt:
halt