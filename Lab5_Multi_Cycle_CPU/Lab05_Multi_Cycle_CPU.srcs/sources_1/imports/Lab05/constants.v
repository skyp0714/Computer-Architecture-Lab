`define PERIOD1 100
`define READ_DELAY 30 // delay before memory data is ready
`define WRITE_DELAY 30 // delay in writing to memory
`define MEMORY_SIZE 256 // size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16 // instead of 2^16 words to reduce memory
`define ROM_SIZE 16
`define ROM_ADDR_SIZE 4
`define ALUROM_ADDR_SIZE 5

`define NUM_TEST 56
`define TESTID_SIZE 5

// state declaration
`define STATE_IF 0
`define STATE_ID_WWD 1
`define STATE_ID_JMP 2
`define STATE_ID_JAL 3
`define STATE_ID_JPR 4
`define STATE_ID_JRL 5
`define STATE_ID_HLT 6
`define STATE_ID 7
`define STATE_EX_BR 8
`define STATE_EX_RALU 9
`define STATE_EX_IALU 10
`define STATE_WB_RALU 11
`define STATE_WB_IALU 12
`define STATE_MEM_LW 13
`define STATE_MEM_SW 14
`define STATE_WB_LW 15

// ALUROM addr
`define R_ADD 5'b00000
`define R_SUB 5'b00001
`define R_AND 5'b00010
`define R_ORR 5'b00011
`define R_NOT 5'b00100
`define R_TCP 5'b00101
`define R_SHL 5'b00110
`define R_SHR 5'b00111
`define I_ADI 5'b10100
`define I_ORI 5'b10101
`define I_LHI 5'b10110
`define I_LWD 5'b10111
`define I_SWD 5'b11000
`define I_BNE 5'b10000
`define I_BEQ 5'b10001
`define I_BGZ 5'b10010
`define I_BLZ 5'b10011
`define I_JMP 5'b11001
`define I_JAL 5'b11010

//OPCODE
`define ALU_ADD 4'b0000
`define ALU_SUB 4'b0001
`define ALU_AND 4'b0010
`define ALU_ORR 4'b0011
`define ALU_NOT 4'b0100
`define ALU_TCP 4'b0101
`define ALU_SHL 4'b0110
`define ALU_SHR 4'b0111
`define ALU_JMP 4'b1000
`define ALU_ADI 4'b1001
`define ALU_ORI 4'b1010
`define ALU_LHI 4'b1011
`define ALU_BNE 4'b1100
`define ALU_BEQ 4'b1101
`define ALU_BGZ 4'b1110
`define ALU_BLZ 4'b1111