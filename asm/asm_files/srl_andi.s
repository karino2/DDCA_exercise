// expect: $2=0x3f
lui $1, 7487 // 0x1d3f
ori $1, $1, 42439 // 0xa5c7, $1 = 0x1d3fa5c7
srl $2, $1, 16 // $2 = 0x00001d3f
andi $2, $2, 255 // $2 = 0x3f
halt