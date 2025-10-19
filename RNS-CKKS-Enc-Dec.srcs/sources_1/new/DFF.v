`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/15/2025 02:43:14 PM
// Design Name: 
// Module Name: DFF
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


module DFF(
        input       clk,
        input       rstn,  // active low reset
        input       D,
        output reg  Q
    );
    
    always @(posedge clk) begin
        if (~rstn) 
            Q <= 1'b1;
        else
            Q <= D;
    end
    
endmodule
