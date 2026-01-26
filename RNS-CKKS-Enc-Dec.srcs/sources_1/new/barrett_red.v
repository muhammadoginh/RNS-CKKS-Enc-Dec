`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 01:46:48 PM
// Design Name: 
// Module Name: barrett_red
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


module barrett_red #(
        parameter BW_IN  = 64,
        parameter BW_OUT = 48
    )(
        input                           clk,
        input                           rstn,
        input       [BW_IN-1:0]         PRNG_IN,
        input       [BW_OUT-1:0]        q,  // Modulus 
        output reg  [BW_OUT-1:0]        M   // Output: PRNG_IN mod q
    );
    
    reg  [BW_IN-1:0] PRNG_REG;
    wire [BW_IN-1:0] PRNG_REG_D;
    reg  [BW_OUT-1:0] q_REG;
    wire [BW_OUT-1:0] q_REG_D;
    
    wire [BW_OUT-1:0] result;
    
    wire [BW_IN-BW_OUT:0] r;
    
    wire [BW_OUT/2-1:0] q_high, q_low;
    
    wire [41-1:0] z0, z1;
    
    
    always @(posedge clk) begin
        if (~rstn) begin
            PRNG_REG <= 0;
            q_REG    <= 0;
        end else begin 
            PRNG_REG <= PRNG_IN;
            q_REG    <= q;
        end
    end
    
    
    assign r = PRNG_REG[BW_IN-1:BW_OUT];
    assign {q_high, q_low} = q_REG;
    
    
    delay #(.N(1), .BW(BW_IN)) delay_PRNG_REG(
        .clk(clk),
        .rstn(rstn),
        .in(PRNG_REG),
        .out(PRNG_REG_D)
    );
    
    delay #(.N(1), .BW(BW_OUT)) delay_q_REG(
        .clk(clk),
        .rstn(rstn),
        .in(q_REG),
        .out(q_REG_D)
    );
    
    dsp_mul #(.A_WIDTH(24), .B_WIDTH(17)) mul_z1(
        .clk(clk),
        .in1(q_high),
        .in2(r),
        .out(z1)
    );
    
    dsp_mul #(.A_WIDTH(24), .B_WIDTH(17)) mul_z0(
        .clk(clk),
        .in1(q_low),
        .in2(r),
        .out(z0)
    );
    
    assign result = PRNG_REG_D - (z1 << 24) - z0;
    
    always @(posedge clk) begin
        if (~rstn) begin
            M <= 0;
        end else begin 
            M <= result;
            if (result > q_REG_D) begin
                M <= result - q_REG_D;
            end
        end
    end


endmodule
