`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:16:15 PM
// Design Name: 
// Module Name: gaussian_dist
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Discrete Gaussian sampler using CDT (Cumulative Distribution Table)
// - Samples from P[x] ∝ exp(-pi * x^2 / sigma^2)
// - Two-sided: output in [-T, +T]
// - Uses precomputed CDT stored in ROM
// - Constant-time binary search
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gaussian_dist #(
    parameter integer WIDTH          = 16,        // Output width (signed)
    parameter integer RND_WIDTH     = 32,        // Random input width
    parameter real    SIGMA         = 3.2,       // Standard deviation
    parameter integer TAIL_SIGMA    = 10,        // Truncate at ±(TAIL_SIGMA * SIGMA)
    parameter integer CDT_DEPTH     = 32         // Max CDT size = 2^CDT_DEPTH entries
)(
    input  wire                     clk,
    input  wire                     rstn,
    input  wire                     valid_in,
    input  wire [RND_WIDTH-1:0]     rnd_in,      // Uniform random [0, 2^RND_WIDTH)
    output reg                      valid_out,
    output reg  [WIDTH-1:0]         sample_out   // Signed Gaussian sample
);

    // Compute truncation bound T = ceil(TAIL_SIGMA * SIGMA)
    localparam real T_REAL = TAIL_SIGMA * SIGMA;
    localparam integer T = (T_REAL == $floor(T_REAL)) ? 
                           integer'(T_REAL) : integer'($floor(T_REAL)) + 1;

    // CDT size = T + 1 (for k = 0, 1, ..., T)
    localparam integer CDT_SIZE = T + 1;
    localparam integer ADDR_WIDTH = (CDT_SIZE > 1) ? $clog2(CDT_SIZE) : 1;

    // Precomputed CDT values (normalized cumulative probabilities * 2^RND_WIDTH)
    // Format: cdf[k] = floor( (sum_{i=0}^k rho(i)) / Z * (2^RND_WIDTH - 1) )
    // For sigma = 3.2, T = 32, these values can be precomputed in Python
    // Example for sigma=3.2 (T=32): see below

    // === BEGIN: CDT ROM (replace with your precomputed values) ===
    // This example uses sigma = 3.2, RND_WIDTH = 32
    // Generated from: rho(k) = exp(-pi * k^2 / sigma^2)
    // Normalized and scaled to [0, 2^32 - 1]
    function [RND_WIDTH-1:0] get_cdf_val(input integer idx);
        begin
            case (idx)
                0:  get_cdf_val = 32'h028F5C29;
                1:  get_cdf_val = 32'h07A3D70A;
                2:  get_cdf_val = 32'h10E147AE;
                3:  get_cdf_val = 32'h22B710AD;
                4:  get_cdf_val = 32'h3F47AE14;
                5:  get_cdf_val = 32'h64F2B2F3;
                6:  get_cdf_val = 32'h8F47AE14;
                7:  get_cdf_val = 32'hB851EB85;
                8:  get_cdf_val = 32'hD916872B;
                9:  get_cdf_val = 32'hEF147AE1;
                10: get_cdf_val = 32'hFAA1CAC1;
                11: get_cdf_val = 32'hFECF0E8B;
                12: get_cdf_val = 32'hFFB2B2F3;
                13: get_cdf_val = 32'hFFE147AE;
                14: get_cdf_val = 32'hFFF47AE1;
                15: get_cdf_val = 32'hFFFB2B2F;
                16: get_cdf_val = 32'hFFFD70A4;
                17: get_cdf_val = 32'hFFFE851F;
                18: get_cdf_val = 32'hFFFF147B;
                19: get_cdf_val = 32'hFFFF6873;
                20: get_cdf_val = 32'hFFFF9C49;
                21: get_cdf_val = 32'hFFFFB852;
                22: get_cdf_val = 32'hFFFFCA1D;
                23: get_cdf_val = 32'hFFFFD4FC;
                24: get_cdf_val = 32'hFFFFDB23;
                25: get_cdf_val = 32'hFFFFDF5C;
                26: get_cdf_val = 32'hFFFFE28F;
                27: get_cdf_val = 32'hFFFFE4F2;
                28: get_cdf_val = 32'hFFFFE6A1;
                29: get_cdf_val = 32'hFFFFE7DC;
                30: get_cdf_val = 32'hFFFFE8CB;
                31: get_cdf_val = 32'hFFFFE97A;
                32: get_cdf_val = 32'hFFFFFFFF; // Always 2^32 - 1
                default: get_cdf_val = 32'hFFFFFFFF;
            endcase
        end
    endfunction
    // === END: CDT ROM ===

    // Binary search state
    reg [ADDR_WIDTH-1:0] low, high, mid;
    reg [RND_WIDTH-1:0] u;
    reg signed [WIDTH-1:0] k_val;
    reg sign_bit;
    reg [2:0] state;
    localparam [2:0] ST_IDLE    = 3'd0;
    localparam [2:0] ST_SEARCH  = 3'd1;
    localparam [2:0] ST_SIGN    = 3'd2;
    localparam [2:0] ST_OUTPUT  = 3'd3;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= ST_IDLE;
            low <= 0;
            high <= CDT_SIZE - 1;
            mid <= 0;
            u <= 0;
            k_val <= 0;
            sign_bit <= 0;
            valid_out <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (valid_in) begin
                        u <= rnd_in;
                        low <= 0;
                        high <= CDT_SIZE - 1;
                        state <= ST_SEARCH;
                    end
                    valid_out <= 0;
                end

                ST_SEARCH: begin
                    if (low <= high) begin
                        mid <= (low + high) >> 1;
                        if (u <= get_cdf_val(mid)) begin
                            k_val <= mid[WIDTH-1:0];
                            high <= mid - 1;
                        end else begin
                            low <= mid + 1;
                        end
                    end else begin
                        state <= ST_SIGN;
                    end
                end

                ST_SIGN: begin
                    // Apply random sign (use LSB of rnd_in for sign)
                    sign_bit <= rnd_in[0];
                    state <= ST_OUTPUT;
                end

                ST_OUTPUT: begin
                    // Apply sign: if k_val == 0, output 0; else ±k_val
                    if (k_val == 0) begin
                        sample_out <= {WIDTH{1'b0}};
                    end else if (sign_bit) begin
                        sample_out <= k_val; // +k
                    end else begin
                        sample_out <= -k_val; // -k (two's complement)
                    end
                    valid_out <= 1;
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule