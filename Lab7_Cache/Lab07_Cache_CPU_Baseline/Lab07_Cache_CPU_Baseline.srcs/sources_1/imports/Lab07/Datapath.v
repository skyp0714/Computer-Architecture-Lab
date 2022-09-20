`define WORD_SIZE 16 
`include "opcodes.v"

//datapath for pipelined cpu
module Datapath(
  input reset_n, clk,                                                               // used for reset PC and RF write
  input ALUSrcA, memwrite, memtoreg, memread, RegWrite, isHalt, isLWD,              // 1bit control signals
  input [1:0] RegDst, PCSrc, ALUSrcB,                                               // 2bit control signals
  input [3:0] ALUOp,                                                                // control signal for ALU
  input [`WORD_SIZE-1:0] PC,                                                        // PC register
  output [`WORD_SIZE-1:0] WWDResult, NextPC,                                        // RF[rs] used for WWD output, nextPC
  output PCUpdate, isFlush, isInvalid, is_halted,
  output [3:0] opcode,
  output [5:0] func,
  output d_readM, d_writeM,
  output [`WORD_SIZE-1:0] d_address, d_data_store,
  input [`WORD_SIZE-1:0] d_data_load,  Inst
  );
// inner register/wire
reg isFirst;
wire taken, IFFlush, Cout;
wire [1:0] rs, rt, rd, WriteAddr, Dest_ID, ID_fwd_rs, ID_fwd_rt, EX_fwd_A, EX_fwd_B;
wire [`WORD_SIZE-1:0] ResPC, PredPC, data_WB, ReadA_ID, ReadB_ID, LinkPC_ID, operand1, operand2, ALUResult_EX, MemData_MEM, ReadA_fwd_ID, ReadB_fwd_ID, ReadA_fwd_EX, ReadB_fwd_EX;     
wire [11:0] Offset_ID;
// Hazard Detection Unit Signals
reg IStall, DStall, IFBubble_ID;
wire PCStall, IFStall, IDStall, EXEStall, RAWStall;
wire IDBubble, WBBubble;
// pipeline registers
reg [`WORD_SIZE-1:0] Inst_ID, PC_ID, PC_EX, PredPC_ID, ReadA_EX, ReadB_EX, ALUResult_MEM, ReadB_MEM, MemData_WB, ALUResult_WB;
reg [11:0] Offset_EX;
reg [1:0] Dest_EX, Dest_MEM, Dest_WB, RS_EX, RT_EX;
// pipeline signals
reg isFlush_ID, ALUSrcA_EX, memwrite_EX, memread_EX, RegWrite_EX, memwrite_MEM, memread_MEM, RegWrite_MEM, RegWrite_WB, isHalt_EX, isHalt_MEM, isHalt_WB, memtoreg_EX, memtoreg_MEM, memtoreg_WB;
reg isLWD_EX, isLWD_MEM;
reg [1:0] ALUSrcB_EX;
reg [3:0] ALUOp_EX;


// for initial condition
always @(posedge clk) begin
  if(~reset_n) isFirst <= 1;
  else if(isFirst) isFirst <= 0;
end

// Stall conditions
assign PCStall = RAWStall || IStall || DStall;
assign IFStall = RAWStall || DStall;
assign IDStall = DStall;
assign EXEStall = DStall;
assign IFBubble = IStall & !DStall & !RAWStall;
assign IDBubble = RAWStall & !DStall;
assign WBBubble = DStall;
assign isInvalid = IFStall || isFlush_ID;

// IF stage
BTB BTB(.clk(clk), .reset_n(reset_n), .taken(taken), .addr(PC_ID), .PC(PC), .ResPC(ResPC), .PredPC(PredPC), .isInvalid(isInvalid));
assign NextPC = IFFlush ? ResPC : PredPC;
assign PCUpdate = !PCStall || IFFlush;
// Instruction stall: read for 2 cycles
always @(posedge clk)begin
  if(~reset_n) IStall <= 0;
  else if(PCUpdate) IStall <= 1;
  else if(IStall) IStall<= 0;
end
// IF/ID pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    isFlush_ID <= 1;
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
    isFlush_ID <= IFFlush || IFBubble;
  end
end

// ID stage
assign isFlush = isFlush_ID;
assign {opcode, rs, rt, rd, func} = Inst_ID;
assign Offset_ID = Inst_ID[11:0];
assign Dest_ID = RegDst[1] ? 2'd2 : (RegDst[0] ? rd : rt);    // select address to write (0: rt, 1: rd, 2: 2'd2)
assign WWDResult = ReadA_fwd_ID;
assign ReadA_fwd_ID = ID_fwd_rs[1] ? data_WB : (ID_fwd_rs[0] ? ALUResult_MEM : ReadA_ID); // forawrded $rs value (0: ID, 1: MEM, 2: WB)
assign ReadB_fwd_ID = ID_fwd_rt[1] ? data_WB : (ID_fwd_rt[0] ? ALUResult_MEM : ReadB_ID); // forawrded $rt value (0: ID, 1: MEM, 2: WB)
PCResolveUnit PCR(.offset(Offset_ID), .PredPC(PredPC_ID), .OldPC(PC_ID), .taken(taken), .ResPC(ResPC), .IFFlush(IFFlush), .Btype(opcode[1:0]), .ReadA(ReadA_fwd_ID), .ReadB(ReadB_fwd_ID), .PCSrc(PCSrc), .isInvalid(isInvalid));
HazardDetectionUnit HDU(.dest({Dest_EX, Dest_MEM, Dest_WB}), .RegWrite({RegWrite_EX, RegWrite_MEM, RegWrite_WB}), .Inst(Inst_ID), .stall(RAWStall), .isFlush(isFlush_ID), .isLWD_EX(isLWD_EX), .isLWD_MEM(isLWD_MEM));
RF RF1(.write(RegWrite_WB), .clk(clk), .reset_n(reset_n), .addr1(rs), .addr2(rt), .addr3(WriteAddr), .data3(data_WB), .data1(ReadA_ID), .data2(ReadB_ID));
IDForwardingUnit IDFU( .RegWrite_MEM(RegWrite_MEM), .RegWrite_WB(RegWrite_WB), .rs(rs), .rt(rt), .Dest_MEM(Dest_MEM), .Dest_WB(Dest_WB), .ID_fwd_rs(ID_fwd_rs), .ID_fwd_rt(ID_fwd_rt));

// ID/EX pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    ReadA_EX <= 0;
    ReadB_EX <= 0;
    Offset_EX <= 0;
    PC_EX <= 0;
  end else if(IDStall) begin
    // hold value
  end else if(IDBubble) begin
    {ALUOp_EX, ALUSrcA_EX, ALUSrcB_EX} <= 0;
    {memwrite_EX, memread_EX, isLWD_EX} <= 0;
    {RegWrite_EX, memtoreg_EX, isHalt_EX} <= 0;
  end else begin
    {ALUOp_EX, ALUSrcA_EX, ALUSrcB_EX} <= {ALUOp, ALUSrcA ,ALUSrcB};
    {memwrite_EX, memread_EX, isLWD_EX} <= {memwrite, memread, isLWD};
    {RegWrite_EX, memtoreg_EX, isHalt_EX} <= {RegWrite, memtoreg, isHalt};
    ReadA_EX <= ReadA_ID;
    ReadB_EX <= ReadB_ID;
    Offset_EX <= Offset_ID;
    PC_EX <= PC_ID;
    Dest_EX <= Dest_ID;
    {RS_EX, RT_EX} <= {rs, rt};
  end
end

// EX stage
assign ReadA_fwd_EX = EX_fwd_A[1] ? data_WB : (EX_fwd_A[0] ? ALUResult_MEM : ReadA_EX);     // forawrded $rs value (0: readA_EX, 1: MEM, 2: WB)
assign ReadB_fwd_EX = EX_fwd_B[1] ? data_WB : (EX_fwd_B[0] ? ALUResult_MEM : ReadB_EX);     // forawrded $rt value (0: readA_EX, 1: MEM, 2: WB)
assign operand1 = ALUSrcA_EX ? 1 : ReadA_fwd_EX;                                            // select operand1 (0: RF[rs], 1: 1)
assign operand2 = ALUSrcB_EX[1] ? PC_EX: (ALUSrcB_EX[0] ? Offset_EX[7:0] : ReadB_fwd_EX);   // select operand2 (0: RF[rt], 1: IR[7:0], 1: PC)
ALU ALU1(.A(operand1), .B(operand2), .Cin(1'b0), .OP(ALUOp_EX), .C(ALUResult_EX), .Cout(Cout));
EXForwardingUnit EXFU( .RegWrite_MEM(RegWrite_MEM), .RegWrite_WB(RegWrite_WB), .rs(RS_EX), .rt(RT_EX), .Dest_MEM(Dest_MEM), .Dest_WB(Dest_WB), .EX_fwd_A(EX_fwd_A), .EX_fwd_B(EX_fwd_B));

// EX/MEM pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    ALUResult_MEM <= 0;
    ReadB_MEM <= 0;
    Dest_MEM <= 0;
  end else if(EXEStall) begin
    // hold value
  end else begin
    {memwrite_MEM, memread_MEM, isLWD_MEM} <= {memwrite_EX, memread_EX, isLWD_EX};
    {RegWrite_MEM, memtoreg_MEM, isHalt_MEM} <= {RegWrite_EX, memtoreg_EX, isHalt_EX};
    ALUResult_MEM <= ALUResult_EX;
    ReadB_MEM <= ReadB_fwd_EX;
    Dest_MEM <= Dest_EX;
  end
end

// MEM stage
assign {d_readM, d_writeM} = {memread_MEM, memwrite_MEM};
assign d_address = ALUResult_MEM;
assign d_data_store = ReadB_MEM;
assign MemData_MEM = d_data_load;
// Data stall: read for 2 cycles
always @(d_address) begin
  if(memread_MEM || memwrite_MEM) DStall <= 1;
end

//MEM/WB pipeline
always @(posedge clk) begin
  if(~reset_n) begin
    MemData_WB <= 0;
    Dest_WB <= 0;
    ALUResult_WB <= 0;
  end else if(WBBubble) begin
    {RegWrite_WB, memtoreg_WB, isHalt_WB} <= 0;
  end else begin
    {RegWrite_WB, memtoreg_WB, isHalt_WB} <= {RegWrite_MEM, memtoreg_MEM, isHalt_MEM};
    MemData_WB <= MemData_MEM;
    Dest_WB <= Dest_MEM;
    ALUResult_WB <= ALUResult_MEM;
  end
  if(~reset_n) DStall <= 0;
  else if(DStall) DStall <= 0;
end

// WB stage
assign WriteAddr = Dest_WB;
assign data_WB = memtoreg_WB ? MemData_WB : ALUResult_WB;  // sleect data to write (0: ALUResult, 1: MemData)
assign is_halted = isHalt_WB;

endmodule
