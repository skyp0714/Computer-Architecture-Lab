///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: PC Resolve Unit

// DEFINITIONS

module PCResolveUnit(
    input [11:0] offset,
    input [15:0] PredPC, OldPC, ReadA, ReadB,
    input [1:0] PCSrc, Btype,
    input isFlush, isStall,
    output reg taken,
    output reg IFFlush, 
    output reg [15:0] ResPC
    );
    
    reg bcond;
    always @(*) begin
        case(Btype)
            2'b00: bcond = (ReadA != ReadB);                // BNE
            2'b01: bcond = (ReadA == ReadB);                // BEQ 
            2'b10: bcond = (!ReadA[15]) && (|ReadA[14:0]);  // BGZ
            2'b11: bcond = (ReadA[15]) && (|ReadA[14:0]);   // BLZ
        endcase    
    end

    always @(*) begin
        case(PCSrc)
            2'b00:begin             // non-branch instructions
                ResPC = OldPC + 1;
                taken = 0;
            end 
            2'b01: begin            // branch instructions
                if(bcond)begin
                    ResPC = OldPC + 1 + {{8{offset[7]}}, offset[7:0]};
                    taken = 1;
                end else begin
                    ResPC = OldPC + 1;
                    taken = 0;
                end
            end
            2'b10: begin            // Jump target address
                ResPC = {OldPC[15:12], offset};
                taken = 1;
            end
            2'b11: begin            // Jump to register
                ResPC = ReadA;
                taken = 1;
            end
        endcase
        // determine whether to flush the fetched instruction
        if((PredPC != ResPC) && !isFlush) IFFlush = 1;
        else IFFlush = 0;
    end

    
endmodule

