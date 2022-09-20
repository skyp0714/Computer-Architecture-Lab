///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: BTB

// DEFINITIONS

module BTB(
    input clk, reset_n, taken, isFlush, isStall,
    input [15:0] PC, ResPC, addr,
    output reg [15:0] PredPC
    );
    wire [7:0] BTBidx, tag;
    assign {tag, BTBidx} = PC;
    reg [7:0] Tag[255:0];
    reg [15:0] Branch[255:0];
    reg [1:0] state[255:0];
    reg [1:0] next_state;
    //FSM
    // state transition
    integer i;
    always @(posedge clk)begin
        if(~reset_n)begin
            for(i=0;i<256;i=i+1)begin
                state[i] <= 2'b11;              // initilaized to state 11
            end
        end else state[addr[7:0]] <= next_state; 
    end
    // next state evaluation (2bit hysterysis counter)
    always @(*) begin
        if(!isStall && !isFlush && (Tag[addr[7:0]] == addr[15:8])) begin
            case(state[addr[7:0]])
                2'b00: 
                    if(taken) next_state = 2'b01;
                    else next_state = 2'b00;
                2'b01: 
                    if(taken) next_state = 2'b11;
                    else next_state = 2'b00;
                2'b10: 
                    if(taken) next_state = 2'b11;
                    else next_state = 2'b00;
                2'b11: 
                    if(taken) next_state = 2'b11;
                    else next_state = 2'b10;
            endcase
        end
    end
    // BTB prediction
    always @(*) begin
        if((Tag[BTBidx] == tag) && (state[BTBidx] > 2'b01)) PredPC = Branch[BTBidx];
        else PredPC = PC + 1;
    end
    // BTB Update
    always @(negedge clk) begin
        if(!isStall && !isFlush && taken) begin     // only when its not speculative
            Tag[addr[7:0]] <= addr[15:8];
            Branch[addr[7:0]] <= ResPC;
        end
    end
endmodule

