`define WORD_SIZE 16
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus request (BR) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus grant (BG) signal 
*         WRITE signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

module DMA (
    input CLK, BG,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    input cmd,
    output reg BR, WRITE,
    output [`WORD_SIZE - 1 : 0] addr, 
    output [4 * `WORD_SIZE - 1 : 0] data,
    output reg [1:0] offset,
    output reg interrupt);

    // send data/address to the memory only when granted to the DMA
    assign data = BG ? edata : 64'dz;
    assign addr = BG ? 16'h01f4 + 4*offset : 16'dz;
    
    reg [1:0] delay;
    always @(posedge CLK) begin
        // handling signals for each cases
        if(interrupt) begin                             // deassert interrupt signal after one cycle
            interrupt <= 0;
            offset <= 2'bzz;
        end else if(cmd && BG && !BR) begin             // generate end signal
            interrupt <= 1;
            WRITE <= 1'bz;
        end else if(cmd && !BG) begin                    // DMA is started
            BR <= 1;
            delay <= 0;
            offset <= 0;
            interrupt <= 0;
        end else if(BG && delay==3 && offset==2) begin  // 12 words sending done
            BR <= 0;
            offset <= 0;
        end else if(BG) begin                           // sending 4words
            WRITE <= 1;
            delay <= delay + 1;
            if(delay == 3) offset <= offset + 1;        // send next offset
        end
    end
endmodule


