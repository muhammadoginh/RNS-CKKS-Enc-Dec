`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:16:35 PM
// Design Name: 
// Module Name: ternary_dist
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Ternary sampler: outputs -1, 0, or +1 based on programmable thresholds
// Ternary Distribution: maps 32-bit PRNG output to {-1, 0, +1}
// Formula: sample = -1 + (prng_input % 3)
// Ultra-fast: no loops, no rejection, fully combinational
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ternary_dist #(
        parameter BW  = 32
    )(
        input                   clk,
        input                   rstn,
        input  [31:0]           prng_input,   // Raw 32-bit PRNG output (e.g., from MT19937)
        output reg signed [1:0] sample  // Ternary value: -1 (2'b11), 0 (2'b00), +1 (2'b01)
    );

    reg [31:0] prng_reg;

    wire [15:0] even_bits;
    wire [15:0] odd_bits;
    
    reg [4:0] even_sum;  // max = 16 --> 5 bits
    reg [4:0] odd_sum;   // max = 16 --> 5 bits
    
    reg [4:0] pos_diff;
    
    always @(posedge clk) begin
        if(~rstn) begin
            prng_reg <= 0;
        end else begin
            prng_reg <= prng_input;
        end
    end
    
    // Extract even and odd bits
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : extract_bits
            assign even_bits[i] = prng_reg[2*i];
            assign odd_bits[i]  = prng_reg[2*i + 1];
        end
    endgenerate
    
    // Combine partial sums (simple linear adder tree)
    always @(*) begin
        integer j;
        even_sum = 0;
        odd_sum  = 0;
        for (j = 0; j < 16; j = j + 1) begin
            even_sum = even_sum + even_bits[j];
            odd_sum  = odd_sum  + odd_bits[j];
        end
        
        if (even_sum > odd_sum) begin
            pos_diff = even_sum - odd_sum;
        end else begin
            pos_diff = 18 - odd_sum + even_sum;
        end
    end
    

//    // Efficient modulo-3 for 32-bit input (optimized for synthesis)
//    wire [1:0] mod3;
//    assign mod3 = pos_diff % 3'd3;
    
    // Since pos_diff <= 17 (6 bits), use direct mapping
    reg [1:0] mod3;
    always @(*) begin
        case (pos_diff)
            0,3,6,9,12,15: mod3 = 2'd0;
            1,4,7,10,13,16: mod3 = 2'd1;
            2,5,8,11,14,17: mod3 = 2'd2;
            default: mod3 = 2'd0; // Prevent latch
        endcase
    end
    
    // Map {0,1,2} -> {-1,0,1}
    always @(posedge clk) begin
        case (mod3)
            2'd0: sample <= -1;  // 2'b11 in 2's complement
            2'd1: sample <=  0;  // 2'b00
            2'd2: sample <=  1;  // 2'b01
        endcase
    end

endmodule