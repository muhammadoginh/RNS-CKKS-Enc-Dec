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
// Input: random bits (at least 2 bits needed)
// Probabilities:
//   P(-1) = THRESHOLD1 / 2^RND_WIDTH
//   P(0)  = (THRESHOLD2 - THRESHOLD1) / 2^RND_WIDTH
//   P(+1) = (2^RND_WIDTH - THRESHOLD2) / 2^RND_WIDTH
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ternary_dist #(
    parameter integer WIDTH        = 16,      // Output width (for -1 in two's complement)
    parameter integer RND_WIDTH   = 32,      // Width of random input (≥2)
    parameter integer THRESHOLD1  = 32'd858993459, // = 0.25 * 2^32  → P(-1) = 25%
    parameter integer THRESHOLD2  = 32'd2576980377  // = 0.75 * 2^32  → P(0) = 50%, P(+1)=25%
)(
    input  wire                     clk,
    input  wire                     rstn,
    input  wire                     valid_in,
    input  wire [RND_WIDTH-1:0]     rnd_in,      // Random bits (uniform)
    output reg                      valid_out,
    output reg  [WIDTH-1:0]         sample_out   // Signed: -1, 0, or +1
);

    // Internal: interpret rnd_in as unsigned integer in [0, 2^RND_WIDTH)
    wire [RND_WIDTH-1:0] rand_val = rnd_in;

    // Decision logic (combinational)
    always @(*) begin
        if (rand_val < THRESHOLD1) begin
            // -1 in two's complement
            sample_out = {WIDTH{1'b1}}; // e.g., 16'hFFFF for WIDTH=16
        end else if (rand_val < THRESHOLD2) begin
            sample_out = {WIDTH{1'b0}}; // 0
        end else begin
            sample_out = {{WIDTH-1{1'b0}}, 1'b1}; // +1
        end
    end

    // Register valid_out (1-cycle latency, aligned with sample_out)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
        end
    end

endmodule