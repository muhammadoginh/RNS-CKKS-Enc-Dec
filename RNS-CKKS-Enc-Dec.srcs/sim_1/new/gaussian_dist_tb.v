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

    // DUT Parameters
    localparam CLK_PERIOD = 10; // 100 MHz clock
    
    // DUT IO
    reg                       clk;
    reg                       rstn;
    reg               [31:0]  prng_input;
    wire  signed      [4:0]   sample;
    
    // DUT Instance
    gaussian_dist uut (
        .clk(clk),
        .rstn(rstn),
        .prng_input(prng_input),
        .sample(sample)
    );
    
    // Clock generation
    always begin
        clk = 1'b1;
        #(CLK_PERIOD/2);
        clk = 1'b0;
        #(CLK_PERIOD/2);
    end
    
    // Test procedure
    initial begin
        // Initialize
        rstn = 1'b0;
        prng_input = 32'd0;
        #20;
        rstn = 1'b1;
        #10;
        
        $display("Starting Gaussian Dist Testbench");
//        $display("Testing boundary conditions...");
        
//        // Test all boundary values (critical indices)
//        test_boundary(0, -10);      // Start of -10
//        test_boundary(1, -9);       // Start of -9
//        test_boundary(2, -9);       // End of -9
//        test_boundary(3, -8);       // Start of -8
//        test_boundary(7, -8);       // End of -8
//        test_boundary(8, -7);       // Start of -7
//        test_boundary(18, -7);      // End of -7
//        test_boundary(19, -6);      // Start of -6
//        test_boundary(39, -6);      // End of -6
//        test_boundary(40, -5);      // Start of -5
//        test_boundary(76, -5);      // End of -5
//        test_boundary(77, -4);      // Start of -4
//        test_boundary(133, -4);     // End of -4
//        test_boundary(134, -3);     // Start of -3
//        test_boundary(213, -3);     // End of -3
//        test_boundary(214, -2);     // Start of -2
//        test_boundary(316, -2);     // End of -2
//        test_boundary(317, -1);     // Start of -1
//        test_boundary(435, -1);     // End of -1
//        test_boundary(436, 0);      // Start of 0
//        test_boundary(560, 0);      // End of 0
//        test_boundary(561, 1);      // Start of +1
//        test_boundary(679, 1);      // End of +1
//        test_boundary(680, 2);      // Start of +2
//        test_boundary(782, 2);      // End of +2
//        test_boundary(783, 3);      // Start of +3
//        test_boundary(862, 3);      // End of +3
//        test_boundary(863, 4);      // Start of +4
//        test_boundary(919, 4);      // End of +4
//        test_boundary(920, 5);      // Start of +5
//        test_boundary(956, 5);      // End of +5
//        test_boundary(957, 6);      // Start of +6
//        test_boundary(977, 6);      // End of +6
//        test_boundary(978, 7);      // Start of +7
//        test_boundary(988, 7);      // End of +7
//        test_boundary(989, 8);      // Start of +8
//        test_boundary(993, 8);      // End of +8
//        test_boundary(994, 9);      // Start of +9
//        test_boundary(995, 9);      // End of +9
//        test_boundary(996, 10);     // Only +10
        
//        $display("Boundary tests PASSED!");
        
        // Test random values across full range
        $display("Testing random values across full range...");
        test_random_values();
        
        $display("All tests PASSED!");
        $finish;
    end
    
    // Task to test a specific boundary condition
    task test_boundary;
        input [9:0] test_mod;
        input signed [4:0] expected;
        begin
            // Set PRNG input to give specific mod997 value
            prng_input = test_mod; // Since test_mod < 997, mod997 = test_mod
            #10; // Wait for 2 clock cycles
            
            if (sample !== expected) begin
                $display("ERROR: mod997=%0d, expected=%0d, got=%0d", test_mod, expected, sample);
                $finish;
            end else begin
                $display("PASS: mod997=%0d -> %0d", test_mod, sample);
            end
        end
    endtask
    
    // Task to test random values
    task test_random_values;
        integer i;
        integer test_val;
        begin
            for (i = 0; i < 65536; i = i + 1) begin
                test_val = $urandom_range(0, 996);
                prng_input = test_val;
                #10;
                
                // Verify output is in valid range
                if (sample < -10 || sample > 10) begin
                    $display("ERROR: sample=%0d out of range [-10,10] for mod997=%0d", sample, test_val);
                    $finish;
                end
            end
            $display("Random value tests PASSED!");
        end
    endtask
    

endmodule