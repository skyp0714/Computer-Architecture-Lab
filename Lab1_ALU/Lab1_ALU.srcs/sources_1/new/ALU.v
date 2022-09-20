`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/12 21:14:34
// Design Name: 
// Module Name: ALU
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

module ALU(
    input [15:0] A,B,
    input Cin,
    input [3:0] OP,
    output reg [15:0] C,
    output reg Cout
    );
    //temporary 17-bit reg to handle carry-out bit
    reg [16:0] tmp;
    
    always @(*) 
        begin
            Cout = 0;
            case(OP)
               //Arithmetic
                4'b0000:    //ADD
                    begin
                        tmp = {1'b0, A} + {1'b0, B} + {15'b0, Cin};
                        Cout = tmp[16];
                        C = tmp[15:0];
                    end
                4'b0001:    //SUB
                    begin
                        tmp = {1'b0, A} - {1'b0, B} - {15'b0, Cin};
                        Cout = tmp[16];
                        C = tmp[15:0];
                    end
                //Birwise Boolean operation
                4'b0010:    //ID
                    C = A;
                4'b0011:    //NAND
                    C = ~(A & B);
                4'b0100:    //NOR
                    C = ~(A | B);
                4'b0101:    //XNOR
                    C = ~(A ^ B);
                4'b0110:    //NOT
                    C = ~A;
                4'b0111:    //AND
                    C = A & B;
                4'b1000:    //OR
                    C = A | B;
                4'b1001:    //XOR
                    C = A ^ B;
                //Shifting
                4'b1010:    //LRS
                    C = A >> 1;
                4'b1011:    //ARS
                    C = {A[15], A[15:1]};
                4'b1100:    //RR
                    C = {A[0], A[15:1]};
                4'b1101:    //LLS
                    C = A << 1;
                4'b1110:    //ALS
                    C = {A[14:0], A[0]};
                4'b1111:    //RL
                    C = {A[14:0], A[15]};
            endcase
        end

endmodule
