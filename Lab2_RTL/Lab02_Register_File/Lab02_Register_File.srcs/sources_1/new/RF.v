`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/16 21:23:19
// Design Name: 
// Module Name: RF
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RF(
    input write, clk, reset_n,
    input [1:0] addr1, addr2, addr3,
    input [15:0] data3,
    output [15:0] data1, data2
    );
    integer i;
    reg [15:0] register_array[3:0];
    
    assign data1 = register_array[addr1];
    assign data2 = register_array[addr2];
    
    always @ (posedge clk, negedge reset_n) begin
        if(~reset_n)
            for(i=0;i<4;i=i+1)
                register_array[i] <= 16'b0;
        else if(write) 
            register_array[addr3] <= data3;
    end
    
endmodule

