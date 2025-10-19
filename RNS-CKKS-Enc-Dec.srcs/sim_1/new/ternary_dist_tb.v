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
    localparam integer WIDTH      = 16;
    localparam integer RND_WIDTH  = 32;
    localparam integer NUM_TESTS  = 100_000;

    // Thresholds for P(-1)=0.25, P(0)=0.5, P(+1)=0.25
    localparam integer THRESHOLD1 = 32'd858993459;  // 0.25 * 2^32
    localparam integer THRESHOLD2 = 32'd2576980377; // 0.75 * 2^32

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
    ternary_dist #(
        .WIDTH(WIDTH),
        .RND_WIDTH(RND_WIDTH),
        .THRESHOLD1(THRESHOLD1),
        .THRESHOLD2(THRESHOLD2)
    ) u_dut (
        .clk(clk),
        .rstn(rstn),
        .valid_in(valid_in),
        .rnd_in(rnd_in),
        .valid_out(valid_out),
        .sample_out(sample_out)
    );

    // Simulation control
    integer count_neg1 = 0;
    integer count_zero = 0;
    integer count_pos1 = 0;
    integer i;
    
    reg signed [WIDTH-1:0] s;
    
    real p_neg1, p_zero, p_pos1;

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
            rnd_in = $urandom(); // 32-bit random

            @(posedge clk);
            valid_in = 0;

            // Sample is available this cycle (combinational output, registered valid)
            if (valid_out) begin
                // Convert sample_out to signed integer for comparison
                s = sample_out;

                if (s == -1) begin
                    count_neg1 = count_neg1 + 1;
                end else if (s == 0) begin
                    count_zero = count_zero + 1;
                end else if (s == 1) begin
                    count_pos1 = count_pos1 + 1;
                end else begin
                    $display("❌ ERROR: Invalid output %d at test %0d", s, i);
                    $finish;
                end
            end
        end
        
                // Report results
        
        p_neg1 = $itor(count_neg1) / $itor(NUM_TESTS);
        p_zero = $itor(count_zero) / $itor(NUM_TESTS);
        p_pos1 = $itor(count_pos1) / $itor(NUM_TESTS);

        $display("Ternary Sampler Test Results (%d samples)", NUM_TESTS);
        $display("P(-1) = %.4f (expected 0.2500)", p_neg1);
        $display("P( 0) = %.4f (expected 0.5000)", p_zero);
        $display("P(+1) = %.4f (expected 0.2500)", p_pos1);

        if (p_neg1 < 0.23 || p_neg1 > 0.27 ||
            p_zero < 0.48 || p_zero > 0.52 ||
            p_pos1 < 0.23 || p_pos1 > 0.27) begin
            $display("WARNING: Probabilities outside expected range.");
        end else begin
            $display("PASS: All probabilities within expected tolerance.");
        end

        $finish;
    end

endmodule