`include "opcodes.v"
`include "constants.v"
//datapath for single cycle cpu
module Datapath(
  input reset_n, clk,                                                               // used for reset PC and RF write
  input PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite, ALUSrcA,       // 1bit control signals
  input [1:0] memtoreg, RegDst, ALUSrcB, PCSrc,                                     // 2bit control signals
  input [3:0] ALUOp,                                                                // control signal for ALU
  input [`WORD_SIZE-1:0] PC,                                                        // PC register
  input [`WORD_SIZE-1:0] MemData,                                                   // data read form memory
  output [`WORD_SIZE-1:0] NextPC,                                                   // next PC
  output [`WORD_SIZE-1:0] WWDResult,                                                // RF[rs] used for WWD output
  output [`WORD_SIZE-1:0] MemAddr,                                                  // address to read memory
  output reg [`WORD_SIZE-1:0] B,                                                    // RF[rt] used for SW
  output PCUpdate,                                                                  // whether PC<-NPC or not
  output [3:0] opcode,
  output [5:0] func
  );
// inner register/wire
reg [`WORD_SIZE-1:0] A, ALUOut, IR, MDR;
wire bcond, Cout;
wire [1:0] WriteAddr;
wire [`WORD_SIZE-1:0] read1, read2, dataw, ALUResult, operand1, operand2;     // read register is used in ALU
wire [1:0] rs,rt, rd;
wire [11:0] imm;

// PC datapath
assign NextPC = PCSrc[1] ? read1 : (PCSrc[0] ?  ALUOut : ALUResult);  // select PCsource (0: ALUResult, 1: ALUOut, 2: RF[rs])
assign PCUpdate = PCWrite | (bcond & PCCond);                         // jmp or PC+1 | branch taken

// RF datapath
assign {rs, rt, rd} = IR[11:6];
assign WriteAddr = RegDst[1] ? 2'd2 : (RegDst[0] ? rd : rt);    // select address to write (0: rt, 1: rd, 2: 2'd2)
assign dataw = memtoreg[1] ? PC: (memtoreg[0] ? ALUOut : MDR);  // sleect data to write (0: MDR, 1: ALUOut, 2: PC)
RF RF1(.write(RegWrite), .clk(clk), .reset_n(reset_n), .addr1(rs), .addr2(rt), .addr3(WriteAddr), .data3(dataw), .data1(read1), .data2(read2));
assign WWDResult = read1;

// ALU datapath
assign imm = IR[11:0];
assign operand1 = ALUSrcA ? A : PC;                             // select operand1 (0: PC, 1: RF[rs])
assign operand2 = ALUSrcB[1] ? imm : (ALUSrcB[0] ? 1'b1 : B);   // select operand2 (0: RF[rt], 1:  1'b1, 2: IR[11:0])
ALU ALU1(.A(operand1), .B(operand2), .Cin(1'b0), .OP(ALUOp), .C(ALUResult), .Cout(Cout), .bcond(bcond) );

// assign outputs
assign MemAddr = IorD ? ALUOut : PC;   // select memory address to access (0: PC, 1: ALUOut)
assign opcode = IR[15:12];
assign func = IR[5:0];

// register Update
always @(posedge clk) begin
    if(IRWrite) IR <= MemData;
    MDR <= MemData;
    A <= read1;
    B <= read2;
    ALUOut <= ALUResult;
end

endmodule
