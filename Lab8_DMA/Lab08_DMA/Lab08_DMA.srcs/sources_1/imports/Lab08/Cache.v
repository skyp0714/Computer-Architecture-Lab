///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: Separated Cache

// DEFINITIONS

module Cache(
    input clk, reset_n, BG,
    input [15:0] PC_CPU,
    input read_CPU, write_CPU,
    inout [15:0] data_CPU, 
    inout [63:0] data_MEM,
    output reg [15:0] PC_MEM,
    output reg read_MEM, write_MEM, 
    output reg cacheBusy
    );
    integer i;
    reg [15:0] outputData;
    reg [10:0] TagBank [3:0];
    reg valid [3:0];
    reg [63:0] DataBank [3:0]; 
    reg [63:0] writebackData;
    wire [63:0] inputData;
    wire [10:0] tag;
    wire [1:0] idx, g;
    wire hit;
    assign tag = PC_CPU[15:4];
    assign idx = PC_CPU[3:2];
    assign g = PC_CPU[1:0];
    assign hit = (TagBank[idx] == tag) && valid[idx];
    assign data_CPU = read_CPU ? outputData : 16'dz;
    assign data_MEM = write_MEM ? writebackData : 64'dz;
    assign inputData = read_MEM ? data_MEM : 64'dz;

    reg [32:0] num_read_hit, num_read_miss, num_write_hit, num_write_miss;
    localparam IDLE = 3'b000, R1 = 3'b001, R2 = 3'b010, R3 = 3'b011, R4 = 3'b100, W1 = 3'b101, W2 = 3'b110, W3 = 3'b111;
    reg [2:0] state, next_state;
    always @(posedge clk) begin
        if(~reset_n)begin
            for(i=0;i<4;i=i+1)  valid[i] <= 0;
            state <= IDLE;
            num_read_hit <= 0;
            num_read_miss <= 0;
            num_write_hit <= 0;
            num_write_miss <= 0;
        end else begin
            state <= next_state;
            // logic for counting hit rate
            if(next_state == IDLE)begin
                if(read_CPU) begin
                    if(state == IDLE && hit) num_read_hit <= num_read_hit + 1;
                    else if(state == R4) num_read_miss <= num_read_miss + 1;
                end else if(write_CPU) begin
                    if(hit) num_write_hit <= num_write_hit + 1;
                    else num_write_miss <= num_write_miss + 1;
                end
            end
        end
    end
    // state transition
    always @(*)begin
        case(state)
            IDLE: begin
                if(BG && !hit  && (read_CPU || write_CPU)) next_state = IDLE;
                else if(!BG && read_CPU) begin
                    if(hit) next_state = IDLE;
                    else next_state = R1;
                end else if(!BG && write_CPU) begin
                    next_state = W1;
                end else next_state = IDLE;
            end
            R1: begin
                if(BG) next_state = IDLE;
                else if(read_CPU) next_state = R2;
                else next_state = IDLE;
            end
            R2: begin
                if(read_CPU) next_state = R3;
                else next_state = IDLE;
            end
            R3: begin
                if(read_CPU) next_state = R4;
                else next_state = IDLE;
            end
            R4: next_state = IDLE;
            W1: begin
                if(BG) next_state = IDLE;
                else next_state = W2;
            end
            W2: next_state = W3;
            W3: next_state = IDLE;
        endcase
    end
    // update tag, data, valid
    // output: cacheBusy, read_MEM, write_MEM
    always @(*) begin
        case(state)
            IDLE: begin
                read_MEM = 0;
                write_MEM = 0;
                writebackData = 64'dz;
                if(BG && !hit && (read_CPU || write_CPU)) begin
                    cacheBusy = 1;
                end else if(read_CPU) begin
                    if(hit) begin
                        outputData = DataBank[idx][16*g +: 16];
                        cacheBusy = 0;
                    end else  cacheBusy = 1;
                end else if(write_CPU) begin
                    DataBank[idx][16*g +: 16] = data_CPU;
                    cacheBusy = 1;
                    read_MEM = 0;
                    write_MEM = 1;
                    writebackData[15:0] = data_CPU;
                    PC_MEM = PC_CPU;
                end else cacheBusy = 0;
            end
            R1: begin
                read_MEM = 1;
                write_MEM = 0;
                PC_MEM = {tag, idx, 2'b0};
            end
            R4: begin
                DataBank[idx] = inputData;
                valid[idx] = 1;
                TagBank[idx] = tag;
            end
            W3: begin
                cacheBusy = 0;
            end
        endcase
    end

endmodule

