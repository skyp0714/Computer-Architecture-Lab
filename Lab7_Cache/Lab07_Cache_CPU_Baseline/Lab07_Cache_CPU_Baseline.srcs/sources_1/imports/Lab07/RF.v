///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 2018-18238 SKY
// Description: 4 16bit register file

// DEFINITIONS

module RF(
    input write, clk, reset_n,
    input [1:0] addr1, addr2, addr3,
    input [15:0] data3,
    output reg [15:0] data1, data2
    );
    integer i;
    reg [15:0] register_array[3:0];
    
    // internal forwarding and read
    always @(*) begin
        if((addr3 == addr1) && write) data1 = data3;
        else data1 = register_array[addr1];
        if((addr3 == addr2) && write) data2 = data3;
        else data2 = register_array[addr2];
    end

    // synchronous read
    always @ (posedge clk, negedge reset_n) begin
        if(~reset_n)
            for(i=0;i<4;i=i+1)
                register_array[i] <= 16'b0;
        else if(write) 
            register_array[addr3] <= data3;
    end
    
endmodule

