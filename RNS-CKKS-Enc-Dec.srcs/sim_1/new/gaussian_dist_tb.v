`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:17:16 PM
// Design Name: 
// Module Name: gaussian_dist_tb
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


module gaussian_dist_tb();


    // Parameters matching the DUT
    localparam integer WIDTH      = 16;
    localparam integer RND_WIDTH  = 32;
    localparam real    SIGMA      = 3.2;
    localparam integer TAIL_SIGMA = 10;
    localparam integer NUM_TESTS  = 1000; // Reduce for simulation speed

    // DUT signals
    reg                     clk;
    reg                     rstn;
    reg                     valid_in;
    reg [RND_WIDTH-1:0]     rnd_in;
    wire                    valid_out;
    wire [WIDTH-1:0]        sample_out;

    // Clock generation
    always #5 clk = ~clk; // 100 MHz

    // Instantiate DUT
    gaussian_dist #(
        .WIDTH(WIDTH),
        .RND_WIDTH(RND_WIDTH),
        .SIGMA(SIGMA),
        .TAIL_SIGMA(TAIL_SIGMA)
    ) u_dut (
        .clk(clk),
        .rstn(rstn),
        .valid_in(valid_in),
        .rnd_in(rnd_in),
        .valid_out(valid_out),
        .sample_out(sample_out)
    );
    
    reg signed [WIDTH-1:0] s;

    // Simulation control
    integer i;
    integer count_zero = 0;
    integer count_nonzero = 0;
    integer max_abs = 0;

    initial begin
        // Initialize
        clk = 0;
        rstn = 0;
        valid_in = 0;
        rnd_in = 0;

        // Release reset
        #20 rstn = 1;

        // Run tests
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            @(posedge clk);
            valid_in = 1;
            rnd_in = $urandom();

            // Wait for valid output (takes multiple cycles due to state machine)
            valid_in = 0;
            while (!valid_out) begin
                @(posedge clk);
            end

            // Convert to signed for analysis
            s = sample_out;

            // Print first 10 samples
            if (i < 10) begin
                $display("Sample %02d: %d", i+1, s);
            end

            // Validate range: |s| <= T = ceil(10 * 3.2) = 32
            if (s < -32 || s > 32) begin
                $display("ERROR: Sample %d = %d is outside [-32, 32]!", i+1, s);
                $finish;
            end

            // Statistics
            if (s == 0) count_zero = count_zero + 1;
            else count_nonzero = count_nonzero + 1;

            if ($abs(s) > max_abs) max_abs = $abs(s);
        end

        // Report results
        $display("\n=== Gaussian Sampler Test Results ===");
        $display("Total samples: %d", NUM_TESTS);
        $display("Zero samples:  %d (%.2f%%)", count_zero, 
                 (100.0 * $itor(count_zero)) / $itor(NUM_TESTS));
        $display("Non-zero:      %d", count_nonzero);
        $display("Max |sample|:  %d (expected <= 32)", max_abs);
        $display("PASS: All samples in valid range.");

        $finish;
    end

endmodule