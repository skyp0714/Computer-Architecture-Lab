`define WORD_SIZE 16 
`include "opcodes.v"

//datapath for pipelined cpu
module Datapath(
  input reset_n, clk,                                                               // used for reset PC and RF write
  input ALUSrcB, memwrite, memread, RegWrite, isHalt,                               // 1bit control signals
  input [1:0] RegDst, PCSrc, memtoreg,                                              // 2bit control signals
  input [3:0] ALUOp,                                                                // control signal for ALU
  input [`WORD_SIZE-1:0] PC,                                                        // PC register
  output [`WORD_SIZE-1:0] WWDResult, NextPC,
  output PCUpdate, isFlush, isStall,
  output [3:0] opcode,
  output [5:0] func,
  output d_readM, d_writeM, is_halted,
  output [`WORD_SIZE-1:0] d_address, d_data_store,
  input [`WORD_SIZE-1:0] d_data_load,  Inst
  );
// inner register/wire
reg isFirst;
wire taken, IFFlush, stall, Cout;
wire [1:0] rs, rt, rd, WriteAddr, Dest_ID;
wire [`WORD_SIZE-1:0] ResPC, PredPC, data_WB, ReadA_ID, ReadB_ID, LinkPC_ID, operand1, operand2, ALUResult_EX, MemData_MEM;
wire [11:0] Offset_ID;
// pipeline registers
reg [`WORD_SIZE-1:0] Inst_ID, PC_ID, PredPC_ID, ReadA_EX, ReadB_EX, LinkPC_EX, ALUResult_MEM, ReadB_MEM, LinkPC_MEM, MemData_WB, ALUResult_WB, LinkPC_WB;
reg [11:0] Offset_EX;
reg [1:0] Dest_EX, Dest_MEM, Dest_WB;
// pipeline signals
reg isFlush_ID, ALUSrcB_EX, memwrite_EX, memread_EX, RegWrite_EX, memwrite_MEM, memread_MEM, RegWrite_MEM, RegWrite_WB, isHalt_EX, isHalt_MEM, isHalt_WB;
reg [1:0] memtoreg_EX, memtoreg_MEM, memtoreg_WB;
reg [3:0] ALUOp_EX;
// Hazard Detection Unit Signals
wire PCStall, IFStall, IDStall;

// for initial condition
always @(posedge clk) begin
  if(~reset_n) isFirst <= 1;
  else if(isFirst) isFirst <= 0;
end

// IF stage
BTB BTB(.clk(clk), .reset_n(reset_n), .taken(taken), .addr(PC_ID), .PC(PC), .ResPC(ResPC), .PredPC(PredPC));
assign NextPC = IFFlush ? ResPC : PredPC;
assign PCUpdate = !PCStall;
// IF/ID pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    isFlush_ID <= 0;
    Inst_ID <= 0;
    PC_ID <= 0;
    PredPC_ID <= 0;
    isFlush_ID <= 0;
  end else if(IFStall) begin
    // hold value
  end else begin
    isFirst <= 0;
    Inst_ID <= Inst;
    PC_ID <= PC;
    PredPC_ID <= PredPC;
    isFlush_ID <= IFFlush;
  end
end

// ID stage
assign isFlush = isFlush_ID;
assign {opcode, rs, rt, rd, func} = Inst_ID;
assign Offset_ID = Inst_ID[11:0];
assign {PCStall, IFStall, IDStall} = {3{stall}};
assign Dest_ID = RegDst[1] ? 2'd2 : (RegDst[0] ? rd : rt);    // select address to write (0: rt, 1: rd, 2: 2'd2)
assign LinkPC_ID = PC_ID + 1;
assign isStall = stall;
assign WWDResult = ReadA_ID;
PCResolveUnit PCR(.offset(Offset_ID), .PredPC(PredPC_ID), .OldPC(PC_ID), .taken(taken), .ResPC(ResPC), .IFFlush(IFFlush), .Btype(opcode[1:0]), .ReadA(ReadA_ID), .ReadB(ReadB_ID), .PCSrc(PCSrc), .isFlush(isFlush_ID));
HazardDetectionUnit HDU(.dest({Dest_EX, Dest_MEM, Dest_WB}), .RegWrite({RegWrite_EX, RegWrite_MEM, RegWrite_WB}), .Inst(Inst_ID), .stall(stall), .isFlush(isFlush_ID));
RF RF1(.write(RegWrite_WB), .clk(clk), .reset_n(reset_n), .addr1(rs), .addr2(rt), .addr3(WriteAddr), .data3(data_WB), .data1(ReadA_ID), .data2(ReadB_ID));
// ID/EX pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    ReadA_EX <= 0;
    ReadB_EX <= 0;
    Offset_EX <= 0;
    LinkPC_EX <= 0;
  end else if(IDStall) begin
    // hold value
    {ALUOp_EX, ALUSrcB_EX} <= 0;
    {memwrite_EX, memread_EX} <= 0;
    {RegWrite_EX, memtoreg_EX, isHalt_EX} <= 0;
  end else begin
    {ALUOp_EX, ALUSrcB_EX} <= {ALUOp, ALUSrcB};
    {memwrite_EX, memread_EX} <= {memwrite, memread};
    {RegWrite_EX, memtoreg_EX, isHalt_EX} <= {RegWrite, memtoreg, isHalt};
    ReadA_EX <= ReadA_ID;
    ReadB_EX <= ReadB_ID;
    Offset_EX <= Offset_ID;
    LinkPC_EX <= LinkPC_ID;
    Dest_EX <= Dest_ID;
  end
end

// EX stage
assign operand1 = ReadA_EX;                             // select operand1 (0: RF[rs])
assign operand2 = ALUSrcB_EX ? Offset_EX[7:0] : ReadB_EX;   // select operand2 (0: RF[rt], 1: IR[7:0])
ALU ALU1(.A(operand1), .B(operand2), .Cin(1'b0), .OP(ALUOp_EX), .C(ALUResult_EX), .Cout(Cout));
// EX/MEM pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    ALUResult_MEM <= 0;
    ReadB_MEM <= 0;
    Dest_MEM <= 0;
    LinkPC_MEM <= 0;
  end else begin
    {memwrite_MEM, memread_MEM} <= {memwrite_EX, memread_EX};
    {RegWrite_MEM, memtoreg_MEM, isHalt_MEM} <= {RegWrite_EX, memtoreg_EX, isHalt_EX};
    ALUResult_MEM <= ALUResult_EX;
    ReadB_MEM <= ReadB_EX;
    Dest_MEM <= Dest_EX;
    LinkPC_MEM <= LinkPC_EX;
  end
end

// MEM stage
assign {d_readM, d_writeM} = {memread_MEM, memwrite_MEM};
assign d_address = ALUResult_MEM;
assign d_data_store = ReadB_MEM;
assign MemData_MEM = d_data_load;
//MEM/WB pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    MemData_WB <= 0;
    Dest_WB <= 0;
    ALUResult_WB <= 0;
    LinkPC_WB <= 0;
  end else begin
    {RegWrite_WB, memtoreg_WB, isHalt_WB} <= {RegWrite_MEM, memtoreg_MEM, isHalt_MEM};
    MemData_WB <= MemData_MEM;
    Dest_WB <= Dest_MEM;
    ALUResult_WB <= ALUResult_MEM;
    LinkPC_WB <= LinkPC_MEM;
  end
end

// WB stage
assign WriteAddr = Dest_WB;
assign data_WB = memtoreg_WB[1] ? LinkPC_WB: (memtoreg_WB[0] ? MemData_WB : ALUResult_WB);  // sleect data to write (0: ALUResult, 1: MemData, 2: LinkPC)
assign is_halted = isHalt_WB;


endmodule
