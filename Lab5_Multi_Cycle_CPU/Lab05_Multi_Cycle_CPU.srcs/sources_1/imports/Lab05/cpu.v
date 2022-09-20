`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

// MODULE DECLARATION
module cpu (
    output readM, // read from memory
    output writeM, // write to memory
    output [`WORD_SIZE-1:0] address, // current address for data
    inout [`WORD_SIZE-1:0] data, // data being input or output
    input inputReady, // indicates that data is ready from the input port
    input reset_n, // active-low RESET signal
    input clk, // clock signal
    
    // for debuging/testing purpose
    output [`WORD_SIZE-1:0] num_inst, // number of instruction during execution
    output [`WORD_SIZE-1:0] output_port, // this will be used for a "WWD" instruction
    output is_halted // 1 if the cpu is halted
);
// internal wire/reg declaration
wire PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite, ALUSrcA, IsWWD, PCUpdate;            
wire [1:0] memtoreg, RegDst, ALUSrcB, PCSrc;
wire [3:0] ALUOp, opcode;
wire [5:0] func;
wire [`WORD_SIZE-1:0] NPC, MemData, MemAddr, B, readrs;
reg isFirst;
reg [`WORD_SIZE-1:0] PC, count, WWDResult;

//assign output wires
assign address = MemAddr;                             // addr from datapath
assign num_inst = IRWrite ? count : `WORD_SIZE'dz;    // only activated at IF state
assign data = memwrite ? B : `WORD_SIZE'dz;           // write on mem: B->mem[addr]
assign MemData = memread ? data : `WORD_SIZE'dz;      // read form mem: mem[addr]->MemData
assign output_port = WWDResult;
assign readM = memread;                               // read mem when memread high
assign writeM = memwrite;                             // write mem when memwrite high

// connect internal modules
ControlUnit CU(clk, reset_n, opcode, func, PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite, ALUSrcA, is_halted, IsWWD, memtoreg, RegDst, ALUSrcB, PCSrc, ALUOp); 
Datapath DP (reset_n, clk, PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite, ALUSrcA, memtoreg, RegDst, ALUSrcB, PCSrc, ALUOp, PC, MemData, NPC, readrs, MemAddr, B, PCUpdate, opcode, func);

// Handling WWD
always@(*) begin
  if(IsWWD) WWDResult <= readrs;
end

// PC register & num_inst
always @(posedge clk) begin
  if(~reset_n) begin
    PC <= `WORD_SIZE'd0;        // reset PC to 16'b0
    count <= 0;                 // reset num_inst
    isFirst <= 1;               // if its start of the program
  end else begin
    if(~isFirst & IRWrite) count <= count + 1;         // increment of num_inst only at IF state
    if((~isFirst) & PCUpdate) PC <= NPC;               // for the first time PC should be 16'b0, update when PCUpdate high
    else isFirst <= 0;                                 // should be 0 after first cycle
  end 

end

endmodule
//////////////////////////////////////////////////////////////////////////

