`include "opcodes.v"
`include "constants.v"

// controlunit for single cycle cpu
module ControlUnit(
  input clk, reset_n,
  input [3:0] opcode,                                                                           // opcode part of the instruction
  input [5:0] func,                                                                             // function part of the instruction
  output PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite,  ALUSrcA, IsHalt, IsWWD,  // 1bit control signals        
  output [1:0] memtoreg, RegDst, ALUSrcB, PCSrc,                                                // 2bit control signals
  output [3:0] ALUOp                                                                            // operation code for the ALU
);
// inner reg wire assignment
reg isfirst;
reg [`ROM_ADDR_SIZE-1:0] state, next_state, addr;
wire [17:0] control_read;
reg [`ALUROM_ADDR_SIZE-1:0] operation;

// ROM declaration
CtrlRom CR (.addr(addr), .data(control_read));
ALUCtrlRom ACR(.addr(operation), .data(ALUOp));

// assign signals read form the ROM
assign {PCCond, PCWrite, IorD, memread, memwrite, IRWrite, RegWrite, ALUSrcA, IsHalt, IsWWD, memtoreg, RegDst, ALUSrcB, PCSrc} = control_read;

// sate update
always @(posedge clk) begin
    if(~reset_n)begin
        state <= `STATE_IF;
        isfirst <= 1;
    end else begin 
        if(~isfirst) state <= next_state;   // state 0 at the first time
        else isfirst <= 0;
    end
end

// setting operation(ALUROM address)
always @(*) begin
    case(addr)
        `STATE_IF: operation <= `R_ADD;
        `STATE_ID: operation <= `I_ADI;
        default: operation <= (&opcode) ? func[4:0] : {1'b1, opcode};
    endcase
end

// state logic
always @(*) begin
    if(state != `STATE_ID) addr <= state;
    case(state)
        `STATE_IF:  next_state <= `STATE_ID;    
        `STATE_ID:  begin
            // classify ID states according to opcode and func
            if(opcode == `OPCODE_JAL) addr <= `STATE_ID_JAL;
            else if(opcode == `OPCODE_JMP) addr <= `STATE_ID_JMP;
            else if(opcode == `OPCODE_R) begin
                if(func == `FUNC_WWD) addr <= `STATE_ID_WWD;
                else if(func == `FUNC_JPR) addr <= `STATE_ID_JPR;
                else if(func == `FUNC_JRL) addr <= `STATE_ID_JRL;
                else if(func == `FUNC_HLT) addr <= `STATE_ID_HLT;
                else addr <= `STATE_ID;
            end else addr <= `STATE_ID;
            // evaluate next state
            if(opcode < 4) next_state <= `STATE_EX_BR;
            else if(opcode < 9) next_state <= `STATE_EX_IALU;
            else if(opcode== `OPCODE_R & func < 8) next_state <= `STATE_EX_RALU;
            else next_state <= `STATE_IF;
        end
        `STATE_EX_BR:   next_state <= `STATE_IF;
        `STATE_EX_RALU: next_state <= `STATE_WB_RALU;
        `STATE_EX_IALU: begin
            if(opcode < 7) next_state <= `STATE_WB_IALU;
            else if(opcode == 7) next_state <= `STATE_MEM_LW;
            else if(opcode == 8) next_state <= `STATE_MEM_SW;
            else next_state <= `STATE_IF;
        end
        `STATE_WB_RALU:  next_state <= `STATE_IF;
        `STATE_WB_IALU:  next_state <= `STATE_IF;
        `STATE_MEM_LW:   next_state <= `STATE_WB_LW;
        `STATE_MEM_SW:   next_state <= `STATE_IF;
        `STATE_WB_LW:    next_state <= `STATE_IF;
    endcase
end


endmodule