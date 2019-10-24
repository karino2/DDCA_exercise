// calc 32*4 byte histogram.
// Assume data is from 0x00000.
// place result from 64*4 = 256 byte

beq $0, $31, 1
j after_copy
d2s $0, $0, 32

after_copy:
// data is at 0x0000-0x0080
//
//
// place each histgram result at 4byte int.
// so the result is base-(base+4*256)
// 
// result of core0: 0x00080-0x0480
// core1: 0x480-0x880
// core2: 0x880-0xC80
// core3: 0xC80-0x1080 
//
// $5: current sram address for data
// $6: histo result base place.
// $7: target last address.

addi $7, $0, 128

// setup histo base.
muli $6, $31, 1024
addi $6, $6, 128

// setup target sram addr
// core0 0, 0x10, 0x20, ..., 0x70  
// core1 4, 0x14, 0x24, ..., 0x74
// core2 8, 0x18, 0x28, ..., 0x78
// core3 C, 0x1C, 0x2C, ..., 0x7C
muli $5, $31, 4

// clear result.
// push 0 to all hist area.
// 0x00080-0x1080.
// 
addi $3, $0, 4223 // 0x1080-1, end sentinel

muli $2, $31, 4 // offset for each core.

addi $1, $0, 128 // 0x0080

add $4, $1, $2
sw $0, $4, 0
addi $1, $1, 16
slt $4, $3, $1
beq $4, $0, -5

start_one_word:
// handle one word.
lw $4, $5, 0

// first byte
andi $1, $4, 255
muli $1, $1, 4 // word offset to byte offset.
add $2, $6, $1 // $2=target histgram address
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// second byte
srl $1, $4, 8
andi $1, $1, 255
muli $1, $1, 4 // word offset to byte offset.
add $2, $6, $1
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// third byte
srl $1, $4, 16
andi $1, $1, 255
muli $1, $1, 4 // word offset to byte offset.
add $2, $6, $1
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// fourth byte
srl $1, $4, 24
andi $1, $1, 255
muli $1, $1, 4 // word offset to byte offset.
add $2, $6, $1
lw $3, $2, 0
addi $3, $3, 1
sw $3, $2, 0

// update next target ($5)
addi $5, $5, 16

// if not yet finish, go back to start_one_word.
// if finish, goto finish stage.
slt $1, $5, $7
beq $1, $0, 1 // branch finish if !($5 < 128), that is,  $5 >= 128
j start_one_word


finish:
// aggregate 4 core result to 0x1080-0x1480
// for(cur = $tid*4; cur < 1024; cur +=16) {
//     $1 = 0
//     $2 = [0x0080+cur]
//     $1 += $2
//     $2 = [0x0480+cur]
//     $1 += $2
//     $2 = [0x0880+cur]
//     $1 += $2
//     $2 = [0x0C80+cur]
//     $1 += $2
//     [0x1080+cur] = $1
// }
addi $6, $0, 1024

// $5: cur
muli $5, $31, 4

aggr_one_word:
addi $1, $0, 0
addi $3, $0, 128
add $3, $3, $5 // $3 = 0x0080+cur


lw $2, $3, 0
add $1, $1, $2

lw $2, $3, 1024
add $1, $1, $2

lw $2, $3, 2048
add $1, $1, $2

lw $2, $3, 3072
add $1, $1, $2

sw $1, $3, 4096

addi $5, $5, 16


slt $1, $5, $6
beq $1, $0, 1
j aggr_one_word


// place result from 64*4 = 256 byte
// s2d 256, 0x1080, 256
addi $1, $0, 256
addi $2, $0, 4224
s2d $1, $2, 256

halt