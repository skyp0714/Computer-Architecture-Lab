///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: single cycle cpu

// DEFINITIONS
`define WORD_SIZE 16    // data and address word size
`define OPCODE_R 4'd15  // R type opcode
`define FUNC_WWD 6'd28  // WWD function code

// INCLUDE files
`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions

// MODULE DECLARATION
module cpu (
  output readM,                       // read from memory
  output [`WORD_SIZE-1:0] address,    // current address for data
  inout [`WORD_SIZE-1:0] data,        // data being input or output
  input inputReady,                   // indicates that data is ready from the input port
  input reset_n,                      // active-low RESET signal
  input clk,                          // clock signal

  // for debuging/testing purpose
  output [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
  output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
);
// internal wire/reg declaration
wire PCSrc, RegDst, RegWrite;
wire [1:0] ALUSrc1, ALUSrc2;
wire [3:0] ALUOp;
wire [`WORD_SIZE-1:0] NPC;
reg RM, isFirst;
reg [`WORD_SIZE-1:0] PC, Inst, count;
//assign output wires
assign address = PC;
assign num_inst = count;
assign readM = RM;
// connect internal modules
ControlUnit CU(Inst[15:12], Inst[5:0], PCSrc, RegDst, RegWrite, ALUSrc1, ALUSrc2, ALUOp); 
Datapath DP (reset_n, clk, PCSrc, RegDst, RegWrite, ALUSrc1, ALUSrc2, ALUOp, Inst[11:10], Inst[9:8], Inst[7:6], Inst[7:0], PC, NPC, output_port);

// instruction memory
always @(inputReady) begin
  if(inputReady)begin      
    Inst = data;        // if input is ready, save data at Inst register 
    RM = 0;             // disable read
  end
end

// PC register & num_inst
always @(posedge clk) begin
  if(~reset_n) begin
    PC <= `WORD_SIZE'd0;        // reset PC to 16'b0
    count <= 0;                 // reset num_inst
    isFirst <= 1;               // if its start of the program
  end else begin
    RM <= 1;                    // enable inst memory read
    count <= count + 1;         // increment of num_inst
    if(~isFirst) PC <= NPC;     // for the first time, PC should be 16'b0
    else isFirst <= 0;          // should be 0 after first instruction 
  end 

end

endmodule
//////////////////////////////////////////////////////////////////////////
// controlunit for single cycle cpu
module ControlUnit(
  input [3:0] opcode,                                 // opcode part of instruction
  input [5:0] func,                                   // function part of instruction
  output reg PCSrc, RegDst, RegWrite,                 // selection for PC, register / write enable for RF / is if WWD operation 
  output reg [1:0] ALUSrc1, ALUSrc2,                  // selection for ALU operands
  output reg [3:0] ALUOp                              // operation code for the ALU
);
always @(*) begin
  // default cases
  PCSrc = 0;                        // select PC + 1
  RegDst = 0;                       // write at $rt
  RegWrite = 0;                     // disable write RF
  ALUSrc1 = 0;                      // select read register
  ALUSrc2 = 0;                      // select read register
  ALUOp = 4'b0000;                  // add operation of ALU
  case(opcode)
    `OPCODE_R: begin
      if(func == `FUNC_ADD) begin
        RegDst = 1;                 // write at $rd
        RegWrite = 1;               // enable write RF
      end else if(`FUNC_WWD)              // WWD operation
        ALUOp = 4'b0010;            // identical operation of ALU
    end
    `OPCODE_ADI: begin
      RegWrite = 1;
      ALUSrc2 = 1;                  // select sign extended immediate
    end
    `OPCODE_LHI: begin
      RegWrite = 1;
      ALUSrc1 = 1;                  // select left shifted immediate
      ALUOp = 4'b0010;
    end
    `OPCODE_JMP: begin
      PCSrc = 1;                    // select jumped PC
    end
  endcase
end
endmodule

//datapath for single cycle cpu
module Datapath(
  input reset_n, clk,                       // used for reset PC and RF write
  input PCSrc, RegDst, RegWrite,            // control signals
  input [1:0] ALUSrc1, ALUSrc2,             
  input [3:0] ALUOp,
  input [1:0] rs, rt, rd,                   // register addresses from instruction
  input [7:0] imm,                          // immediate from instruction
  input [`WORD_SIZE-1:0] CurrentPC,         // current PC evaluating
  output [`WORD_SIZE-1:0] NextPC,       // next PC to evaluate
  output [`WORD_SIZE-1:0] ALUResult         // used for RF input and WWD output
  );
// PC datapath
wire [11:0] TargetAddr;
assign TargetAddr = {rs, rt, imm};  // instruction[11:0]
assign NextPC = PCSrc ? {CurrentPC[15:12], TargetAddr} : (CurrentPC + 1);

// RF datapath
wire [1:0] WriteAddr;
assign WriteAddr = RegDst ? rd : rt;    // select address to write
wire [`WORD_SIZE-1:0] read1, read2;     // read register is used in ALU
RF RF1(.write(RegWrite), .clk(clk), .reset_n(reset_n), .addr1(rs), .addr2(rt), .addr3(WriteAddr), .data3(ALUResult), .data1(read1), .data2(read2));

// ALU datapath
wire Cout;
wire [`WORD_SIZE-1:0] operand1, operand2;
assign operand1 = ALUSrc1 ? {imm, {8{1'b0}}} : read1;
assign operand2 = ALUSrc2 ? {{8{imm[7]}}, imm} : read2;     
ALU ALU1(.A(operand1), .B(operand2), .Cin(1'b0), .OP(ALUOp), .C(ALUResult), .Cout(Cout));

endmodule
