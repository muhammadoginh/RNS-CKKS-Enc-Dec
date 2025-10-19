`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/15/2025 02:53:29 PM
// Design Name: 
// Module Name: LFSR_tb
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


module LFSR_tb();
    
    // Testbench signals
    reg clk;
    reg rstn;
    wire out;
    
    
    // Instantiate the LFSR module
    LFSR uut (
        .clk(clk),
        .rstn(rstn),
        .out(out)
    );
    
    // Clock generation
    initial begin
        clk = 1;
        forever #2 clk = ~clk; // 10ns period clock (250MHz)
    end
   
    
    // Test sequence
    initial begin
        rstn = 0;
        
        #4;
        rstn = 1;
        // Display outputs
        $monitor("Time = %0t, clk = %b, out = %b", $time, clk, out);
        
        // Let it run for 20 clock cycles
        #200;
        
        $finish;
    end
    
endmodule