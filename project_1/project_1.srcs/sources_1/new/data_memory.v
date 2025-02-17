`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 01:24:42 PM
// Design Name: 
// Module Name: data_memory
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


module data_memory(input clk,
                    input mem_read,
                    input mem_write,
                    input [31:0] address,
                    input [31:0] write_data,
                    output reg [31:0] read_data);

  reg [31:0] data_mem [0:1023];
  
  integer i;
  initial begin
    for (i = 0; i < 1024; i = i + 1) begin
      data_mem[i] = 32'b0;
    end
  end 
  
  always@(posedge clk) 
    if(mem_write)
      data_mem[address[11:2]] <= write_data;
      
   always@(*) 
    if(mem_read)
      read_data <= data_mem[address[11:2]];   
                                        
endmodule