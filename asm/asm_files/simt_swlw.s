addi $1, $0, 1300

beq $0, $31, 1
j end
sw $0, $1, 0
nop
nop
addi $3, $0, 1300
lw $2, $3, 0
addi $2, $2, 1

end:
halt
