`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/24 21:36:36
// Design Name: 
// Module Name: detector
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//implemented as Mealy-Machine
module detector(
    input clk,
    input reset_n,
    input in,
    output reg out
    );
    parameter start = 2'b00, zero = 2'b01, one = 2'b10;

    reg [1:0] state;
    reg [1:0] nextState;
    reg tmpOut;
    always @(in or state)begin
        case(state)
            start: begin
                tmpOut = 1'b0;
                if(in) nextState = start;
                else nextState = zero;
            end
            zero: begin
                tmpOut = 1'b0;
                if(in) nextState = one;
                else nextState = zero;
            end
            one: begin
                if(in)begin
                    tmpOut = 1'b0;
                    nextState = start;
                end else begin
                    tmpOut = 1'b1;
                    nextState = zero;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if(~reset_n)
            state <= zero;
        else begin
            state <= nextState;
            out <= tmpOut;
        end
    end

endmodule
