///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: 16bit ALU

// DEFINITIONS
`include "opcodes.v"

module ALU(
    input [15:0] A,B,
    input Cin,
    input [3:0] OP,
    output reg [15:0] C,
    output reg Cout
    );
    reg [16:0] tmp;         // temporary 17-bit reg to handle carry-out bit
    always @(*) 
        begin
            Cout = 0;
            case(OP)
                `ALU_ADD:
                    begin
                        tmp = {1'b0, A} + {1'b0, B} + {15'b0, Cin};
                        Cout = tmp[16];
                        C = tmp[15:0];
                    end
                `ALU_SUB:
                    begin
                        tmp = {1'b0, A} - {1'b0, B} - {15'b0, Cin};
                        Cout = tmp[16];
                        C = tmp[15:0];
                    end
                `ALU_AND:
                    C = A & B;
                `ALU_ORR:
                    C = A | B;
                `ALU_NOT:
                    C = ~A;
                `ALU_TCP:
                    C = ~A + 1;
                `ALU_SHL:
                    C = A << 1;
                `ALU_SHR:
                    C = A >> 1;
                `ALU_ADI:
                    C = A + {{8{B[7]}}, B[7:0]};    // A + sign-ext(B)
                `ALU_ORI:
                    C = A | {{8{1'b0}}, B[7:0]};    // A | zero-ext(B)
                `ALU_LHI: 
                    C = {B[7:0], {8{1'b0}}};        // B << 8
                `ALU_IDC:
                    C = A;
            endcase
        end

endmodule
