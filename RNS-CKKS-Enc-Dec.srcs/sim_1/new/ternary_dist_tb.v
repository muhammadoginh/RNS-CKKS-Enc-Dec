`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:16:57 PM
// Design Name: 
// Module Name: ternary_dist_tb
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


module ternary_dist_tb();

  // Parameters
  localparam integer NUM_SAMPLES = 100000;

  // DUT I/O
  reg         clk;
  reg         rstn;
  reg  [31:0] prng_input;
  wire signed [1:0] sample;

  // Instantiate DUT
  ternary_dist dut (
    .clk(clk),
    .rstn(rstn),
    .prng_input(prng_input),
    .sample(sample)
  );

  // Clock generation: 100 MHz (10 ns period)
  initial clk = 1;
  always #5 clk = ~clk;

  // Counters for statistics
  integer neg1_count = 0;
  integer zero_count = 0;
  integer plus1_count = 0;
  integer total_count = 0;

  // Pseudo-random generator (LFSR-style for reproducibility)
  reg [31:0] lfsr = 32'hACE1_1234;
  always @(posedge clk)
    if (rstn)
      lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};

  // Stimulus and collection
  initial begin
    rstn = 0;
    prng_input = 0;
    @(posedge clk);
    rstn = 1;

    repeat (NUM_SAMPLES) begin
      
      prng_input <= lfsr;

      // Record sample from previous cycle (pipeline delay = 1)
      if (total_count > 1) begin
        case (sample)
          -1: neg1_count  = neg1_count  + 1;
           0: zero_count  = zero_count  + 1;
           1: plus1_count = plus1_count + 1;
        endcase
      end
      total_count = total_count + 1;
      @(posedge clk);
    end

    // Wait a few extra cycles to flush pipeline
    repeat (5) @(posedge clk);

    // Display statistics
    $display("=========================================");
    $display("   TERNARY SAMPLER STATISTICS");
    $display("=========================================");
    $display(" Total samples : %0d", total_count);
    $display("  -1 count      : %0d (%.4f %%)", neg1_count,
             100.0 * neg1_count / total_count);
    $display("   0 count      : %0d (%.4f %%)", zero_count,
             100.0 * zero_count / total_count);
    $display("  +1 count      : %0d (%.4f %%)", plus1_count,
             100.0 * plus1_count / total_count);
    $display("=========================================");

    $finish;
  end

endmodule
