`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N, 

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`WORD_SIZE-1:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE-1:0] d_data, 

        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted
);
// internal wire/reg declaration
wire PCUpdate, isFlush, isStall, memread, memwrite, RegWrite, ALUSrcB, isWWD, isHalt;          
wire [1:0] memtoreg, RegDst, PCSrc;
wire [3:0] ALUOp, opcode;
wire [5:0] func;
wire [`WORD_SIZE-1:0] NPC, d_data_store, d_data_load, ReadRS;
reg isFirst;
reg [`WORD_SIZE-1:0] PC, count, WWDResult;

//assign output wires
assign i_address = PC;
assign {i_readM, i_writeM} = 2'b10;
assign num_inst = (isWWD & (!isStall)) ? count : `WORD_SIZE'dz;
assign d_data_load = d_readM ? d_data : `WORD_SIZE'dz;
assign d_data = d_writeM ? d_data_store : `WORD_SIZE'dz;
assign output_port = (isWWD & (!isStall)) ? WWDResult : `WORD_SIZE'dz;

// connect internal modules
ControlUnit CU(
  .clk(Clk), .reset_n(Reset_N), .isFlush(isFlush),
  .opcode(opcode),
  .func(func),
  .ALUSrcB(ALUSrcB), .memwrite(memwrite), .memread(memread), .RegWrite(RegWrite), .isWWD(isWWD), .isHalt(isHalt),
  .RegDst(RegDst), .PCSrc(PCSrc), .memtoreg(memtoreg),
  .ALUOp(ALUOp)
);
Datapath DP(
  .reset_n(Reset_N), .clk(Clk),
  .ALUSrcB(ALUSrcB), .memwrite(memwrite), .memread(memread), .RegWrite(RegWrite), .isHalt(isHalt),
  .RegDst(RegDst), .PCSrc(PCSrc), .memtoreg(memtoreg),
  .ALUOp(ALUOp),
  .PC(PC), 
  .WWDResult(ReadRS), .NextPC(NPC),
  .PCUpdate(PCUpdate), .isFlush(isFlush), .isStall(isStall),
  .opcode(opcode),
  .func(func),
  .d_readM(d_readM), .d_writeM(d_writeM), .is_halted(is_halted),
  .d_address(d_address), .d_data_store(d_data_store),
  .d_data_load(d_data_load),  .Inst(i_data)
  );

// Handling WWD
always@(*) begin
  if(isWWD) WWDResult <= ReadRS;
end
// PC register & num_inst
always @(posedge Clk) begin
  if(~Reset_N) begin
    PC <= `WORD_SIZE'd0;        // reset PC to 16'b0
    count <= 1;                 // reset num_inst
    isFirst <= 1;               // if its start of the program
  end else begin
    if(~isFirst & (!isStall) & (!isFlush)) count <= count + 1;  //increment for non speculative instruction
    if((~isFirst) & PCUpdate) PC <= NPC;                        // for the first time PC should be 16'b0, update when PCUpdate high
    else isFirst <= 0;                                          // should be 0 after first cycle
  end 

end

endmodule
