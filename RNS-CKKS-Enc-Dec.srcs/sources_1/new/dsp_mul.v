`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 12:55:56 PM
// Design Name: 
// Module Name: dsp_mul
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

(* use_dsp = "no" *)
module dsp_mul #(
    parameter A_WIDTH = 26,
    parameter B_WIDTH = 18,
    parameter OUT_WIDTH = A_WIDTH + B_WIDTH
)(
    input                       clk,
    input       [A_WIDTH-1:0]   in1,
    input       [B_WIDTH-1:0]   in2,
    output reg  [OUT_WIDTH-1:0] out
);

    always @(posedge clk) begin
        out <= in1 * in2;
    end
    
endmodule