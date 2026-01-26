`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 04:15:09 PM
// Design Name: 
// Module Name: ternary_dist_with_mod
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


module ternary_dist_with_mod(
    input                   clk,
    input                   rstn,
    input  [31:0]           prng_input,   // Raw 32-bit PRNG output (e.g., from MT19937)
    output reg signed [1:0] sample  // Ternary value: -1 (2'b11), 0 (2'b00), +1 (2'b01)
);

    reg [31:0] prng_reg;
    
    always @(posedge clk) begin
        if(~rstn) begin
            prng_reg <= 0;
        end else begin
            prng_reg <= prng_input;
        end
    end

    // Efficient modulo-3 for 32-bit input (optimized for synthesis)
    wire [1:0] mod3 = prng_reg[31:0] % 3'd3;
    
    // Map {0,1,2} -> {-1,0,1}
    always @(posedge clk) begin
        case (mod3)
            2'd0: sample = -1;  // 2'b11 in 2's complement
            2'd1: sample =  0;  // 2'b00
            2'd2: sample =  1;  // 2'b01
            default: sample = 0; // Never reached
        endcase
    end

endmodule
