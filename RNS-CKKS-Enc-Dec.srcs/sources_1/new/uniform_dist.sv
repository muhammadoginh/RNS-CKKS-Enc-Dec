`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 02:02:12 PM
// Design Name: 
// Module Name: uniform_dist
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


module uniform_dist #(
    parameter integer WIDTH_Q   = 48,
    parameter integer WIDTH_RND = 64
)(
    input  wire                 clk,
    input  wire                 rstn,
    input  wire                 valid_in,
    input  wire [WIDTH_RND-1:0] rnd_in,
    input  wire [WIDTH_Q-1:0]   modulus_q,
    input  wire [WIDTH_RND-1:0] mu,          // precomputed floor(2^WIDTH_RND / q)
    output reg                  valid_out,
    output reg  [WIDTH_Q-1:0]   sample_out
);
    // Internal signals
    reg  [WIDTH_RND-1:0] x_reg;
    reg  [WIDTH_RND-1:0] q_reg;
    reg  [WIDTH_RND-1:0] mu_reg;
    wire [2*WIDTH_RND-1:0] mult_full;
    wire [WIDTH_RND-1:0]   t;
    wire [WIDTH_RND:0]     sub_val;
    wire [WIDTH_Q-1:0]     reduced;
    
    // Stage 1: latch inputs
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            x_reg <= 0;
            q_reg <= 0;
            mu_reg <= 0;
        end else if (valid_in) begin
            x_reg <= rnd_in;
            q_reg <= modulus_q;
            mu_reg <= mu;
        end
    end

    // Stage 2: Barrett reduction
    assign mult_full = x_reg * mu_reg;              // 64x64→128 multiply
    assign t = mult_full[WIDTH_RND +: WIDTH_RND];   // floor((x*mu)/2^k)
    assign sub_val = x_reg - (t * q_reg);
    
    // Correction (ensure 0 <= r < q)
    assign reduced = (sub_val[WIDTH_RND-1:0] >= q_reg[WIDTH_Q-1:0]) ?
                     sub_val[WIDTH_RND-1:0] - q_reg[WIDTH_Q-1:0] :
                     sub_val[WIDTH_RND-1:0];

    // Stage 3: register output
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_out  <= 1'b0;
            sample_out <= {WIDTH_Q{1'b0}};
        end else begin
            valid_out  <= valid_in;
            sample_out <= reduced;
        end
    end

endmodule
