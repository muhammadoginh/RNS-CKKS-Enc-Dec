`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:15:33 PM
// Design Name: 
// Module Name: uniform_dist_tb
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


module uniform_dist_tb();

    // Parameters matching RLWE config: q = 7681
    localparam integer WIDTH_Q   = 13;      // ceil(log2(7681)) = 13
    localparam integer WIDTH_RND = 64;
    localparam integer NUM_TESTS = 20;

    // DUT signals
    reg                 clk;
    reg                 rstn;
    reg                 valid_in;
    reg [WIDTH_RND-1:0] rnd_in;
    reg [WIDTH_Q-1:0]   modulus_q;
    reg [WIDTH_RND-1:0] mu;

    wire                valid_out;
    wire [WIDTH_Q-1:0]  sample_out;

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock

    // Precomputed mu = floor(2^64 / q)
    // q = 7681
    localparam [WIDTH_Q-1:0] Q_VAL = 13'd7681;
    localparam [WIDTH_RND-1:0] MU_VAL = 64'd1529464017187500; // floor(2^64 / 7681)

    // Instantiate DUT
    uniform_dist #(
        .WIDTH_Q(WIDTH_Q),
        .WIDTH_RND(WIDTH_RND)
    ) uut (
        .clk(clk),
        .rstn(rstn),
        .valid_in(valid_in),
        .rnd_in(rnd_in),
        .modulus_q(modulus_q),
        .mu(mu),
        .valid_out(valid_out),
        .sample_out(sample_out)
    );

    // Test process
    integer i;
    initial begin
        // Initialize
        clk = 0;
        rstn = 0;
        valid_in = 0;
        rnd_in = 0;
        modulus_q = Q_VAL;
        mu = MU_VAL;

        // Hold reset
        #20 rstn = 1;

        // Run tests
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            @(posedge clk);
            valid_in = 1;
            rnd_in = $random; // 32-bit random, extended to 64
            // Optionally use $urandom for 64-bit:
            // rnd_in = $urandom();

            @(posedge clk);
            valid_in = 0;

            // Wait for output (valid_out aligns with valid_in in your design)
            @(posedge clk);
            if (valid_out) begin
                if (sample_out >= modulus_q) begin
                    $display("❌ ERROR: sample_out = %d >= modulus_q = %d", sample_out, modulus_q);
                    $finish;
                end else begin
                    $display("✅ Sample %02d: %d (mod %d)", i+1, sample_out, modulus_q);
                end
            end
        end

        $display("✅ All %0d tests passed.", NUM_TESTS);
        $finish;
    end

endmodule