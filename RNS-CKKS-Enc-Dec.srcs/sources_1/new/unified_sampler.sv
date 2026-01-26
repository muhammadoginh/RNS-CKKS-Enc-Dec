`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:17:53 PM
// Design Name: 
// Module Name: unified_sampler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
// Unified Random Sampler (URS)
// - Single 64-bit entropy input per sample
// - Three modes: uniform, ternary, gaussian
// - Shared datapath: ???
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module unified_sampler #(
        parameter BW_IN  = 64,
        parameter BW_OUT = 48
    )(
        input                           clk,
        input                           rstn,
        input             [1:0]         mode,          // 00: uniform, 01: ternary, 10: gaussian
        input             [BW_IN-1:0]   prng_input,    // Raw PRNG
        output reg signed [BW_OUT:0]    sample
    );
    
    localparam [BW_OUT-1:0] q = 48'd281_474_976_710_597;

    // =============== SHARED PRNG REGISTRATION ===============
    // Single PRNG register used by all modes
    reg [BW_IN-1:0] prng_reg;
    always @(posedge clk) begin
        if (~rstn) prng_reg <= 0;
        else prng_reg <= prng_input;
    end
    
    // =============== SHARED COMPARATOR INFRASTRUCTURE ===============
    // Reusable comparator for all threshold/modulo operations
    function [31:0] compare_subtract;
        input [31:0] a, b;
        begin
            compare_subtract = (a >= b) ? (a - b) : a;
        end
    endfunction
    
    // =============== MODE-SPECIFIC LOGIC (NO DUPLICATION) ===============
    // Uniform mode: Barrett reduction (only when needed)
    wire [BW_OUT-1:0] uniform_out;
    wire [BW_IN-1:0] PRNG_REG_D;
    wire [BW_OUT:0] result_D;
    
    wire [BW_IN-BW_OUT:0] r = prng_reg[BW_IN-1:BW_OUT];
    wire [BW_OUT/2-1:0] q_high = q[BW_OUT-1:BW_OUT/2];
    wire [BW_OUT/2-1:0] q_low  = q[BW_OUT/2-1:0];
    
    // Shared DSP multipliers (only instantiated once)
    wire [41-1:0] z0, z1;
    dsp_mul #(.A_WIDTH(BW_OUT/2), .B_WIDTH(BW_IN-BW_OUT)) mul_z1(
        .clk(clk), .in1(q_high), .in2(r), .out(z1)
    );
    dsp_mul #(.A_WIDTH(BW_OUT/2), .B_WIDTH(BW_IN-BW_OUT)) mul_z0(
        .clk(clk), .in1(q_low),  .in2(r), .out(z0)
    );
    
    delay #(.N(1), .BW(BW_IN)) delay_PRNG_REG(
        .clk(clk),
        .rstn(rstn),
        .in(prng_reg[BW_OUT-1:0]),
        .out(PRNG_REG_D)
    );
    
    wire [BW_OUT:0] result = PRNG_REG_D - (z1 << (BW_OUT/2)) - z0;
    
    delay #(.N(1), .BW(BW_OUT+1)) delay_result(
        .clk(clk),
        .rstn(rstn),
        .in(result),
        .out(result_D)
    );
    
    assign uniform_out = compare_subtract(result_D, q);

    
    // Ternary mode: Efficient modulo-3 using shared logic
    wire signed [1:0] ternary_out;
    begin : ternary_logic
        // Use lower 32 bits
        wire [31:0] ternary_prng = prng_reg[31:0];
        // Direct modulo-3 (synthesis-optimized)
        wire [1:0] mod3 = ternary_prng % 3'd3;
        assign ternary_out = (mod3 == 2'd0) ? -1 :
                            (mod3 == 2'd1) ?  0 : 1;
    end
    
    // Gaussian mode: Range comparisons with shared comparators
    wire signed [4:0] gaussian_out;
    begin : gaussian_logic
        localparam TOTAL_WEIGHT = 10'd997;
        wire [9:0] lower_10 = prng_reg[9:0];
        // Use shared comparator function
        wire [9:0] mod997 = compare_subtract(lower_10, TOTAL_WEIGHT);
        
        // Cascaded comparisons (optimized by synthesis)
        assign gaussian_out = (mod997 < 1)   ? -10 :
                             (mod997 < 3)   ? -9  :
                             (mod997 < 8)   ? -8  :
                             (mod997 < 19)  ? -7  :
                             (mod997 < 40)  ? -6  :
                             (mod997 < 77)  ? -5  :
                             (mod997 < 134) ? -4  :
                             (mod997 < 214) ? -3  :
                             (mod997 < 317) ? -2  :
                             (mod997 < 436) ? -1  :
                             (mod997 < 561) ? 0   :
                             (mod997 < 680) ? 1   :
                             (mod997 < 783) ? 2   :
                             (mod997 < 863) ? 3   :
                             (mod997 < 920) ? 4   :
                             (mod997 < 957) ? 5   :
                             (mod997 < 978) ? 6   :
                             (mod997 < 989) ? 7   :
                             (mod997 < 994) ? 8   :
                             (mod997 < 996) ? 9   :
                                              10;
    end
    
    // =============== OUTPUT SELECTION ===============
    always @(posedge clk) begin
        if (~rstn) sample <= 0;
        else begin
            case (mode)
                2'b00: sample <= uniform_out;
                2'b01: sample <= ternary_out;
                2'b10: sample <= gaussian_out;
                default: sample <= 0;
            endcase
        end
    end

endmodule