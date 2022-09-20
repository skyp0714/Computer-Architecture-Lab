`include "opcodes.v"

// controlunit for pipelined cpu
module ControlUnit(
  input clk, reset_n, isFlush,
  input [3:0] opcode,                                                                           // opcode part of the instruction
  input [5:0] func,                                                                             // function part of the instruction
  output reg ALUSrcA, memwrite, memtoreg, memread, RegWrite, isWWD, isHalt, isLWD,              // 1bit control signals
  output reg [1:0] RegDst, PCSrc, ALUSrcB,                                                      // 2bit control signals
  output reg [3:0] ALUOp                                                                        // control signal for ALU
);
always @(*) begin
    {ALUSrcB, ALUSrcA, memwrite, memread, RegWrite, isWWD, isHalt, RegDst, PCSrc, memtoreg, ALUOp, isLWD} = 0;
    if(!isFlush)begin                                   // all signals are 0 for the flushed instruction
        case(opcode)
            `OPCODE_R: begin
                case(func) 
                    `FUNC_ADD: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_ADD;
                    end
                    `FUNC_SUB: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_SUB;
                    end
                    `FUNC_AND: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_AND;
                    end
                    `FUNC_ORR: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_ORR;
                    end
                    `FUNC_NOT: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_NOT;
                    end
                    `FUNC_TCP: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_TCP;
                    end
                    `FUNC_SHL: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_SHL;
                    end
                    `FUNC_SHR: begin
                        RegDst = 1;
                        RegWrite = 1;
                        ALUOp = `ALU_SHR;
                    end
                    `FUNC_WWD: begin
                        isWWD = 1;
                        ALUOp = `ALU_IDC;
                    end 
                    `FUNC_JPR: begin
                        PCSrc = 3;
                    end 
                    `FUNC_JRL: begin
                        RegDst = 2;
                        RegWrite = 1;
                        PCSrc = 3;
                        ALUOp = `ALU_ADD;
                        ALUSrcA = 1;
                        ALUSrcB = 2;
                    end 
                    `FUNC_HLT: begin
                        isHalt = 1;
                    end 
                endcase
            end
            `OPCODE_ADI: begin
                RegWrite = 1;
                ALUSrcB = 1;
                ALUOp = `ALU_ADI;
            end
            `OPCODE_ORI: begin
                RegWrite = 1;
                ALUSrcB = 1;
                ALUOp = `ALU_ORI;
            end
            `OPCODE_LHI: begin
                RegWrite = 1;
                ALUSrcB = 1;
                ALUOp = `ALU_LHI;
            end
            `OPCODE_LWD: begin
                RegWrite = 1;
                ALUSrcB = 1;
                memtoreg = 1;
                ALUOp = `ALU_ADI;
                memread = 1;
                isLWD = 1;
            end
            `OPCODE_SWD: begin
                ALUSrcB = 1;
                memwrite = 1;
                ALUOp = `ALU_ADI;
            end
            `OPCODE_BNE: begin
                PCSrc = 1;
            end
            `OPCODE_BEQ: begin
                PCSrc = 1;
            end
            `OPCODE_BGZ: begin
                PCSrc = 1;
            end
            `OPCODE_BLZ: begin
                PCSrc = 1;
            end
            `OPCODE_JMP: begin
                PCSrc = 2;
            end
            `OPCODE_JAL: begin
                RegDst = 2;
                RegWrite = 1;
                PCSrc = 2;
                ALUOp = `ALU_ADD;
                ALUSrcA = 1;
                ALUSrcB = 2;
            end 
        endcase
    end 
end


endmodule