`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Muhammad Ogin Hasanuddin
// 
// Create Date: 09/15/2025 02:47:02 PM
// Design Name: 
// Module Name: LFSR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Reference: https://ieeexplore.ieee.org/document/11044009
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module LFSR(
        input   clk,
        input   rstn,
        output  out
    );
    
    
    wire D1, D2, D3;
    wire Q1, Q2, Q3;
    wire xor_dff2_dff3;
    
    assign D2 = Q1;
    assign D3 = Q2;
    
    DFF DFF1 (
        .clk(clk),
        .rstn(rstn),
        .D(D1),
        .Q(Q1)
    );
    
    DFF DFF2 (
        .clk(clk),
        .rstn(rstn),
        .D(D2),
        .Q(Q2)
    );
    
    DFF DFF3 (
        .clk(clk),
        .rstn(rstn),
        .D(D3),
        .Q(Q3)
    );
    
    assign xor_dff2_dff3 = Q1 ^ Q3;
    
    assign D1 = xor_dff2_dff3;
    
    assign out = Q3;
    
endmodule
