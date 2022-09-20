`include "opcodes.v"
`include "constants.v"


// ROM for signals except ALUOp
module CtrlRom(
    input [`ROM_ADDR_SIZE-1:0] addr,
    output [17:0] data
    );
    reg [17:0] memory [0:`ROM_SIZE-1];
    
    initial begin
                                    // {PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite,  ALUSrcA, IsHalt, IsWWD, memtoreg, RegDst, ALUSrcB, PCSrc} 
        memory[`STATE_IF]          <= 18'b 0_1_0_1_0_1_0_0_0_0_00_00_01_00;
        memory[`STATE_ID_WWD]      <= 18'b 0_0_0_0_0_0_0_0_0_1_00_00_00_00;
        memory[`STATE_ID_JMP]      <= 18'b 0_1_0_0_0_0_0_0_0_0_00_00_10_00;
        memory[`STATE_ID_JAL]      <= 18'b 0_1_0_0_0_0_1_0_0_0_10_10_10_00;
        memory[`STATE_ID_JPR]      <= 18'b 0_1_0_0_0_0_0_0_0_0_00_00_00_10;
        memory[`STATE_ID_JRL]      <= 18'b 0_1_0_0_0_0_1_0_0_0_10_10_00_10;
        memory[`STATE_ID_HLT]      <= 18'b 0_0_0_0_0_0_0_0_1_0_00_00_00_00;
        memory[`STATE_ID]          <= 18'b 0_0_0_0_0_0_0_0_0_0_00_00_10_00;
        memory[`STATE_EX_BR]       <= 18'b 1_0_0_0_0_0_0_1_0_0_00_00_00_01;
        memory[`STATE_EX_RALU]     <= 18'b 0_0_0_0_0_0_0_1_0_0_00_00_00_00;
        memory[`STATE_EX_IALU ]    <= 18'b 0_0_0_0_0_0_0_1_0_0_00_00_10_00;
        memory[`STATE_WB_RALU ]    <= 18'b 0_0_0_0_0_0_1_0_0_0_01_01_00_00;
        memory[`STATE_WB_IALU ]    <= 18'b 0_0_0_0_0_0_1_0_0_0_01_00_00_00;
        memory[`STATE_MEM_LW ]     <= 18'b 0_0_1_1_0_0_0_0_0_0_00_00_00_00;
        memory[`STATE_MEM_SW ]     <= 18'b 0_0_1_0_1_0_0_0_0_0_00_00_00_00;
        memory[`STATE_WB_LW ]      <= 18'b 0_0_0_0_0_0_1_0_0_0_00_00_00_00;
    end
    assign data = memory[addr];

endmodule

// ROM for ALUOp
module ALUCtrlRom(
    input [`ALUROM_ADDR_SIZE-1:0] addr,
    output [3:0] data
    );
reg [3:0] memory [0:31];

    initial begin
        memory[`R_ADD]  <=  `ALU_ADD;
        memory[`R_SUB]  <=  `ALU_SUB;
        memory[`R_AND]  <=  `ALU_AND;
        memory[`R_ORR]  <=  `ALU_ORR;
        memory[`R_NOT]  <=  `ALU_NOT;
        memory[`R_TCP]  <=  `ALU_TCP;
        memory[`R_SHL]  <=  `ALU_SHL;
        memory[`R_SHR]  <=  `ALU_SHR;
        memory[`I_ADI]  <=  `ALU_ADI;
        memory[`I_ORI]  <=  `ALU_ORI;
        memory[`I_LHI]  <=  `ALU_LHI;
        memory[`I_LWD]  <=  `ALU_ADI;
        memory[`I_SWD]  <=  `ALU_ADI;
        memory[`I_BNE]  <=  `ALU_BNE;
        memory[`I_BEQ]  <=  `ALU_BEQ;
        memory[`I_BGZ]  <=  `ALU_BGZ;
        memory[`I_BLZ]  <=  `ALU_BLZ;
        memory[`I_JMP]  <=  `ALU_JMP;
        memory[`I_JAL]  <=  `ALU_JMP;
    end
    assign data = memory[addr];

endmodule