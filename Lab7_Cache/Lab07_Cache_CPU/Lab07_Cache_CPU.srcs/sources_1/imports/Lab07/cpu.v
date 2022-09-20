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
        inout [63:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [63:0] d_data, 

        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted
);
// internal wire/reg declaration
wire PCUpdate, isFlush, isInvalid, memtoreg, memread, memwrite, RegWrite, ALUSrcA, isWWD, isHalt, isLWD, ICacheBusy, DCacheBusy, dataread, datawrite, readI, IFFlush;
wire [1:0] RegDst, PCSrc, ALUSrcB;
wire [3:0] ALUOp, opcode;
wire [5:0] func;
wire [`WORD_SIZE-1:0] NPC, d_data_store, d_data_load, ReadRS, dataAddr, datavalue;
reg isFirst;
reg [`WORD_SIZE-1:0] PC, count, WWDResult, Instruction, donePC;
wire [63:0] data_MEM_read, data_MEM_write, i_MEM_read, i_MEM_write;
wire [`WORD_SIZE-1:0] Inst;
//assign output wires
assign num_inst = (isWWD & (!isInvalid)) ? count : `WORD_SIZE'dz;
assign output_port = (isWWD & (!isInvalid)) ? WWDResult : `WORD_SIZE'dz;

// connect internal modules
ControlUnit CU(
  .clk(Clk), .reset_n(Reset_N), .isFlush(isFlush),
  .opcode(opcode),
  .func(func),
  .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .memwrite(memwrite), .memread(memread), .RegWrite(RegWrite), .isWWD(isWWD), .isHalt(isHalt), .isLWD(isLWD),
  .RegDst(RegDst), .PCSrc(PCSrc), .memtoreg(memtoreg),
  .ALUOp(ALUOp)
);
Datapath DP(
  .reset_n(Reset_N), .clk(Clk), .ICacheBusy(ICacheBusy), .DCacheBusy(DCacheBusy),
  .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .memwrite(memwrite), .memread(memread), .RegWrite(RegWrite), .isHalt(isHalt),.isLWD(isLWD), .IFFlush(IFFlush),
  .RegDst(RegDst), .PCSrc(PCSrc), .memtoreg(memtoreg),
  .ALUOp(ALUOp),
  .PC(PC), 
  .WWDResult(ReadRS), .NextPC(NPC),
  .PCUpdate(PCUpdate), .isFlush(isFlush), .isInvalid(isInvalid),
  .opcode(opcode),
  .func(func),
  .d_readM(dataread), .d_writeM(datawrite), .is_halted(is_halted),
  .d_address(dataAddr), .d_data_store(d_data_store),
  .d_data_load(d_data_load),  .Inst(Instruction)
  );
assign readI = ((donePC != PC) && !IFFlush) || (count == 1);
Cache IC(
    .clk(Clk), .reset_n(Reset_N),
    .PC_CPU(PC),
    .read_CPU(readI), .write_CPU(0),
    .data_CPU(Inst), 
    .data_MEM(i_data),
    .PC_MEM(i_address),
    .read_MEM(i_readM), .write_MEM(i_writeM), .cacheBusy(ICacheBusy)
    );
// assigning data for DCache
assign d_data_load = dataread ? datavalue : 16'bz;
assign datavalue = datawrite ? d_data_store : 16'bz;
Cache DC(
    .clk(Clk), .reset_n(Reset_N),
    .PC_CPU(dataAddr),
    .read_CPU(dataread), .write_CPU(datawrite),
    .data_CPU(datavalue), 
    .data_MEM(d_data),
    .PC_MEM(d_address),
    .read_MEM(d_readM), .write_MEM(d_writeM), .cacheBusy(DCacheBusy)
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
    if(~isFirst & (!isInvalid)) count <= count + 1;    // only increment for the used instrctions
    if((~isFirst) & PCUpdate) PC <= NPC;               // for the first time PC should be 16'b0, update when PCUpdate high
    else isFirst <= 0;                                 // should be 0 after first cycle
  end 
end
// Fetch Instruction at negedge before losing its data
reg [32:0] num_inst_read;
always @(negedge Clk) begin
  if(~Reset_N) num_inst_read <= 0;
  else if(readI && !ICacheBusy)begin
    num_inst_read <= num_inst_read + 1;
    Instruction <= Inst;
    donePC <= PC;
  end
end

endmodule
