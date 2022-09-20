///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: forwarding unit

// DEFINITIONS

module EXForwardingUnit(
    input RegWrite_MEM, RegWrite_WB,
    input [1:0] rs, rt, Dest_MEM, Dest_WB,
    output reg [1:0] EX_fwd_A, EX_fwd_B
    );
    always @(*)begin
        if((rs == Dest_MEM) && RegWrite_MEM) EX_fwd_A = 1;
        else if((rs == Dest_WB) && RegWrite_WB) EX_fwd_A = 2;
        else EX_fwd_A = 0;
        if((rt == Dest_MEM) && RegWrite_MEM) EX_fwd_B = 1;
        else if((rt == Dest_WB) && RegWrite_WB) EX_fwd_B = 2;
        else EX_fwd_B = 0;
    end
endmodule

module IDForwardingUnit(
    input RegWrite_MEM, RegWrite_WB,
    input [1:0] rs, rt, Dest_MEM, Dest_WB,
    output reg [1:0] ID_fwd_rs, ID_fwd_rt
    );
    always @(*)begin
        if((rs == Dest_MEM) && RegWrite_MEM) ID_fwd_rs = 1;
        else if((rs == Dest_WB) && RegWrite_WB) ID_fwd_rs = 2;
        else ID_fwd_rs = 0;
        if((rt == Dest_MEM) && RegWrite_MEM) ID_fwd_rt = 1;
        else if((rt == Dest_WB) && RegWrite_WB) ID_fwd_rt = 2;
        else ID_fwd_rt = 0;
    end
endmodule