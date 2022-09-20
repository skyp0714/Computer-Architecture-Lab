///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: PC Resolution Unit

// DEFINITIONS

module PCResolveUnit(
    input [11:0] offset,
    input [15:0] PredPC, OldPC, ReadA, ReadB,
    input [1:0] PCSrc, Btype,
    input isFlush,
    output reg taken,
    output reg IFFlush, 
    output reg [15:0] ResPC
    );
    // evaluate branch condition
    reg bcond;
    always @(*) begin
        case(Btype)
            2'b00: bcond = (ReadA != ReadB);
            2'b01: bcond = (ReadA == ReadB);
            2'b10: bcond = (!ReadA[15]) && (|ReadA[14:0]);
            2'b11: bcond = (ReadA[15]) && (|ReadA[14:0]);
        endcase    
    end
    // evaluate next PC
    always @(*) begin
        case(PCSrc)
            2'b00:begin
                ResPC = OldPC + 1;
                taken = 0;
            end 
            2'b01: begin
                if(bcond)begin
                    ResPC = OldPC + 1 + {{8{offset[7]}}, offset[7:0]};
                    taken = 1;
                end else begin
                    ResPC = OldPC + 1;
                    taken = 0;
                end
            end
            2'b10: begin
                ResPC = {OldPC[15:12], offset};
                taken = 1;
            end
            2'b11: begin
                ResPC = ReadA;
                taken = 1;
            end
        endcase
        // determine whether to flush instruction in the IF stage
        if((PredPC != ResPC) && !isFlush) IFFlush = 1;
        else IFFlush = 0;
    end

    
endmodule

