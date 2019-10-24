// calc 32*4 byte histogram.
// Assume data is from 0x00000.
// place result from 64*4 = 256 byte

beq $0, $31, 1
j after_copy
d2s $0, $0, 32

after_copy:
// data is at 0x0000-0x0020
//
// result of core0: 0x00020-0x0120
// core1: 0x120-0x220
// core2: 0x220-0x320
// core3: 0x320-0x420 
//
// $5: current sram address for data
// $6: histo result base place.
// $7: target last address -1 .

addi $7, $0, 31

// setup histo base.
muli $6, $31, 256
addi $6, $6, 32

// setup target sram addr
muli $5, $31, 4


start_one_word:
// handle one word.
lw $4, $5, 0

// first byte
andi $1, $4, 255
add $2, $6, $1 // $2=target histgram address
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// second byte
srl $1, $4, 8
andi $1, $1, 255
add $2, $6, $1
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// third byte
srl $1, $4, 16
andi $1, $1, 255
add $2, $6, $1
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// fourth byte
srl $1, $4, 24
andi $1, $1, 255
add $2, $6, $1
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// update next target ($5)
addi $5, $5, 32

// if not yet finish, go back to start_one_word.
// if finish, goto finish stage.
slt $1, $5, $7
beq $1, $0, 1 // branch finish if 31 < $5
j start_one_word


finish:
// aggregate 4 core result to 0x0420-0x0520
// for(cur = $tid*4; cur < 256; cur +=16) {
//     $1 = 0
//     $2 = [0x0020+cur]
//     $1 += $2
//     $2 = [0x0120+cur]
//     $1 += $2
//     $2 = [0x0220+cur]
//     $1 += $2
//     $2 = [0x0320+cur]
//     $1 += $2
//     [0x0420+cur] = $1
// }
addi $6, $0, 256

// $5: cur
muli $5, $31, 4

aggr_one_word:
addi $1, $0, 0
addi $3, $0, 32
add $3, $3, $5 // $3 = 0x0020+cur


lw $2, $3, 0
add $1, $1, $2

lw $2, $3, 256
add $1, $1, $2

lw $2, $3, 512
add $1, $1, $2

lw $2, $3, 768
add $1, $1, $2

sw $1, $3, 1024

addi $5, $5, 16


slt $1, $5, $6
beq $1, $0, 1
j aggr_one_word


// place result from 64*4 = 256 byte
// s2d 256, 0x0420, 32
addi $1, $0, 256
addi $2, $0, 1056
s2d $1, $2, 32

halt