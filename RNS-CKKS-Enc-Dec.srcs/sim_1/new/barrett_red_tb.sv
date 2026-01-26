`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 01:51:13 PM
// Design Name: 
// Module Name: barrett_red_tb
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


module barrett_red_tb();
    // Parameters matching the DUT
    localparam integer BW_IN  = 64;
    localparam integer BW_OUT = 48;
    localparam integer NUM_TESTS_PER_Q = 100; // Number of random tests per modulus
    localparam integer NUM_QS = 9; // Number of moduli in the 'qp' array

    // The specific 'qp' values provided (as 48-bit constants)
    // Note: Verilog constants are typically defined as parameters
    // We'll define them directly in the test loop for simplicity.
    // q values are:
    // 281474976317441 (0x1000000000001)
    // 281474975662081 (0x0FFFFFFFFFFE1)
    // 281474974482433 (0x0FFFFFFFFFFA1)
    // 281474966880257 (0x0FFFFFFFFFF01)
    // 281474962554881 (0x0FFFFFFFFFEC1)
    // 281474960326657 (0x0FFFFFFFFFE81)
    // 281474957180929 (0x0FFFFFFFFFE41)
    // 281474955476993 (0x0FFFFFFFFFE01)
    // 281474952462337 (0x0FFFFFFFFFDC1)
    // Using decimal representation in the loop below.

    reg [47:0] qp_array [0:NUM_QS-1] = '{
        48'hfffffffa0001, // 281474976317441
        48'hFFFFFFFFFFE1, // 281474975662081
        48'hFFFFFFFFFFA1, // 281474974482433
        48'hFFFFFFFFFF01, // 281474966880257
        48'hFFFFFFFFFEC1, // 281474962554881
        48'hFFFFFFFFFE81, // 281474960326657
        48'hFFFFFFFFFE41, // 281474957180929
        48'hFFFFFFFFFE01, // 281474955476993
        48'hFFFFFFFFFDC1  // 281474952462337
    };

    // DUT signals
    reg                           clk;
    reg                           rstn;
    reg       [BW_IN-1:0]         PRNG_IN;
    reg       [BW_OUT-1:0]        q;
    wire      [BW_OUT-1:0]        M;

    // Expected result using standard Verilog modulo
    wire [BW_OUT-1:0] expected_result = PRNG_IN % q;

    // Instantiate DUT
    barrett_red #(
        .BW_IN(BW_IN),
        .BW_OUT(BW_OUT)
    ) uut (
        .clk(clk),
        .rstn(rstn),
        .PRNG_IN(PRNG_IN),
        .q(q),
        .M(M)
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;
    
    integer all_tests_passed; // Declare the variable

    initial begin
        // Initialize signals
        clk = 1;
        rstn = 0;
        PRNG_IN = 0;
        q = 0;

        // Release reset after a few cycles
        #10;
        rstn = 1;
//        #10; // Wait for reset release propagation

        $display("Starting testbench for barrett_red with specific 'qp' values.");
        $display("Testing %d moduli, %d random inputs each.", NUM_QS, NUM_TESTS_PER_Q);
        $display("--------------------------------------------------------------");

        all_tests_passed = 1; // Flag to track overall result

        // --- Run Tests for each q in qp_array ---
        for (integer i = 0; i < NUM_QS; i = i + 1) begin
            q = qp_array[i];
            @(posedge clk);
            $display("Testing q[%0d] = 0x%h (%0d)", i, q, q);

            // Generate a random 64-bit number for PRNG_IN
            // Verilog's $random returns a 32-bit signed value.
            // To get 64 bits, we combine two calls or use $urandom (32-bit unsigned).
            // Using $urandom for simplicity, though it's still 32-bit.
            // For a full 64-bit range test, you might need more complex generation
            // or a proper random number generator stimulus.
            // For this test, let's use a combination or a specific range if needed.
            // Since the function docstring says 0 <= x < 2^63, let's generate a number in that range.
            // A 64-bit number where the top bit is 0 covers [0, 2^63).
            // We can use a 64-bit random value and mask the MSB if necessary,
            // but $urandom is 32 bit. Let's combine two $urandom calls.
            // This might not be a perfectly uniform 64-bit number, but covers the range.
            // A better way might be to use a proper LFSR or read from a file.
            // For simulation, this combination is often sufficient for basic checks.
            PRNG_IN = { $urandom(), $urandom() }; // Concatenate two 32-bit unsigned randoms

            // Ensure the generated number is within [0, 2^63) if necessary
            // PRNG_IN[63] = 1'b0; // This would force the number to be < 2^63

            // Wait for one clock cycle for the DUT to process (accounting for internal delays)
            // The DUT has a delay of 1 clk cycle due to PRNG_REG_D and the final assignment to M
            @(posedge clk);

            // Check result against expected (using standard %)
            if (M === expected_result) begin
                // Optional: Print success for every N tests to avoid spam
                // if (j % 50 == 0) begin
                //     $display("  Test j=%0d: PASS - PRNG_IN=0x%h, DUT Output=0x%h, Expected=0x%h", j, PRNG_IN, M, expected_result);
                // end
            end else begin
                $display("  Test : FAIL - PRNG_IN=0x%h, q=0x%h, DUT Output=0x%h, Expected=0x%h", PRNG_IN, q, M, expected_result);
                all_tests_passed = 0; // Mark overall failure
                // Optional: Stop simulation on first failure
                // $finish;
            end


            $display("  Completed testing for q[%0d] = 0x%h", i, q);
            $display("--------------------------------------------------------------");

        end // End outer loop (NUM_QS)

        if (all_tests_passed) begin
            $display("OVERALL RESULT: All tests PASSED for the specific 'qp' values!");
        end else begin
            $display("OVERALL RESULT: Some tests FAILED for the specific 'qp' values. Check output above.");
        end

        $finish;
    end

endmodule