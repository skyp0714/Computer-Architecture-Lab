///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: BTB

// DEFINITIONS

module BTB(
    input clk, reset_n, taken, isInvalid,
    input [15:0] PC, ResPC, addr,
    output reg [15:0] PredPC
    );
    wire [7:0] BTBidx, tag;
    assign {tag, BTBidx} = PC;
    reg [7:0] Tag[255:0];
    reg [15:0] Branch[255:0];
    
    // BTB prediction
    always @(*) begin
        if((Tag[BTBidx] == tag)) PredPC = Branch[BTBidx];
        else PredPC = PC + 1;
    end
    // BTB Update
    always @(negedge clk) begin
        if(!isInvalid && taken) begin     // only when its not speculative
            Tag[addr[7:0]] <= addr[15:8];
            Branch[addr[7:0]] <= ResPC;
        end
    end
endmodule

