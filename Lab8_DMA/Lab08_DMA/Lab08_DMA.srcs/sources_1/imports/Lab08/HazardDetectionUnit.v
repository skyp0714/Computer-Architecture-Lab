///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: Hazard Detection Unit

// DEFINITIONS
`include "opcodes.v"

module HazardDetectionUnit(
    input isFlush, isLWD_EX, isLWD_MEM,
    input [5:0] dest,
    input [2:0] RegWrite,
    input [15:0] Inst,
    output reg stall 
    );
    wire [1:0] rs, rt;
    wire EX_RAW, MEM_RAW, WB_RAW;
    reg use_rs, use_rt, isBranch;
    wire [3:0] opcode;
    wire [5:0] func;
    assign {rs, rt} = Inst[11:8];
    assign opcode = Inst[15:12];
    assign func = Inst[5:0];
    // determine the RAW depencies with other stages: EX, MEM, WB
    assign EX_RAW = ((rs == dest[5:4])&& use_rs && RegWrite[2]) || ((rt == dest[5:4])&& use_rt && RegWrite[2]);
    assign MEM_RAW = ((rs == dest[3:2])&& use_rs && RegWrite[1]) || ((rt == dest[3:2])&& use_rt && RegWrite[1]);
    assign WB_RAW = ((rs == dest[1:0])&& use_rs && RegWrite[0]) || ((rt == dest[1:0])&& use_rt && RegWrite[0]);

    always @(*) begin
        // determine whether rs, rt is used in current instruction
        // determine whether current instruction is branch or not
        {use_rs, use_rt, isBranch} = 0;
        if(opcode == `OPCODE_R)begin
            if(func != `FUNC_HLT) use_rs = 1;
            if(func <= `FUNC_ORR) use_rt = 1;
            if(func == `FUNC_JPR) isBranch = 1;
            if(func == `FUNC_JRL) isBranch = 1;
            if(func == `FUNC_WWD) isBranch = 1;
        end else if(opcode <= `OPCODE_BEQ)begin
            use_rs = 1;
            use_rt = 1;
            isBranch = 1;
        end else if(opcode <= `OPCODE_BLZ)begin
            use_rs = 1;
            isBranch = 1;
        end else if(opcode <= `OPCODE_LWD) begin
            if(opcode != `OPCODE_LHI) use_rs = 1;
        end else if(opcode <= `OPCODE_SWD) begin
            use_rs = 1;
            use_rt = 1;
        end else if(opcode <= `OPCODE_JAL) begin
            isBranch = 1;
        end
        // stall condition
        if(isFlush)begin
            stall = 0;
        end else if(isBranch)begin   // for branch instructions
            if(EX_RAW || (MEM_RAW && isLWD_MEM) ) stall = 1;
            else stall = 0;
        end else begin      // for non-branch instructions
            if((EX_RAW && isLWD_EX) || (MEM_RAW && isLWD_MEM)) stall = 1;
            else stall = 0;
        end
    end
endmodule

