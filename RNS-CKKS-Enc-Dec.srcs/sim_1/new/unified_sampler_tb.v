`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:18:10 PM
// Design Name: 
// Module Name: unified_sampler_tb
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


module unified_sampler_tb();

    // Parameters
    localparam integer WIDTH_Q    = 13;      // q = 7681 → 13 bits
    localparam integer WIDTH_OUT  = 16;
    localparam integer RND_WIDTH  = 64;
    localparam integer GAUSS_T    = 32;
    localparam integer CDT_SIZE   = 33;
    localparam integer NUM_TESTS  = 200;     // Reduce for simulation speed

    // Precomputed constants
    localparam [WIDTH_Q-1:0] Q_VAL = 13'd7681;
    localparam [RND_WIDTH-1:0] MU_VAL = 64'd1529464017187500; // floor(2^64 / 7681)

    // Ternary thresholds (25% -1, 50% 0, 25% +1)
    localparam [RND_WIDTH-1:0] T1_TERNARY = 64'h4000000000000000; // 0.25 * 2^64
    localparam [RND_WIDTH-1:0] T2_TERNARY = 64'hC000000000000000; // 0.75 * 2^64

    // DUT signals
    reg                     clk;
    reg                     rstn;
    reg                     valid_in;
    reg [RND_WIDTH-1:0]     rnd_in;
    reg [1:0]               mode;
    reg [WIDTH_Q-1:0]       modulus_q;
    reg [RND_WIDTH-1:0]     mu;
    reg [RND_WIDTH-1:0]     t1_ternary;
    reg [RND_WIDTH-1:0]     t2_ternary;
    wire                    valid_out;
    wire [WIDTH_OUT-1:0]    sample_out;

    // Clock
    always #5 clk = ~clk;

    // Instantiate DUT
    unified_sampler #(
        .WIDTH_Q(WIDTH_Q),
        .WIDTH_OUT(WIDTH_OUT),
        .RND_WIDTH(RND_WIDTH),
        .GAUSS_T(GAUSS_T),
        .CDT_SIZE(CDT_SIZE)
    ) u_dut (
        .clk(clk),
        .rstn(rstn),
        .valid_in(valid_in),
        .rnd_in(rnd_in),
        .mode(mode),
        .modulus_q(modulus_q),
        .mu(mu),
        .t1_ternary(t1_ternary),
        .t2_ternary(t2_ternary),
        .valid_out(valid_out),
        .sample_out(sample_out)
    );
    
    reg signed [WIDTH_OUT-1:0] s;
    integer abs_s;

    // Test control
    integer i;
    integer count_uniform = 0;
    integer count_ternary = 0;
    integer count_gaussian = 0;

    initial begin
        // Initialize
        clk = 0;
        rstn = 0;
        valid_in = 0;
        modulus_q = Q_VAL;
        mu = MU_VAL;
        t1_ternary = T1_TERNARY;
        t2_ternary = T2_TERNARY;

        #20 rstn = 1;

        // ----------------------------
        // Test 1: Uniform mode
        // ----------------------------
        mode = 2'b00; // uniform
        $display("=== Testing UNIFORM mode (q = %d) ===", Q_VAL);
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            valid_in = 1;
            rnd_in = { $urandom(), $urandom() }; // 64-bit random

            valid_in = 0;
            while (!valid_out) @(posedge clk);

            if (sample_out >= Q_VAL) begin
                $display("❌ ERROR: Uniform sample %d >= q!", sample_out);
                $finish;
            end
            if (i < 5) $display("Uniform sample: %d", sample_out);
            count_uniform = count_uniform + 1;
        end

        // ----------------------------
        // Test 2: Ternary mode
        // ----------------------------
        mode = 2'b01; // ternary
        $display("\n=== Testing TERNARY mode ===");
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge clk);
            valid_in = 1;
            rnd_in = { $urandom(), $urandom() };

            valid_in = 0;
            while (!valid_out) @(posedge clk);

            s = sample_out;
            if (s != -1 && s != 0 && s != 1) begin
                $display("❌ ERROR: Ternary sample not in {-1,0,1}: %d", s);
                $finish;
            end
            if (i < 5) $display("Ternary sample: %d", s);
            count_ternary = count_ternary + 1;
        end

        // ----------------------------
        // Test 3: Gaussian mode
        // ----------------------------
        mode = 2'b10; // gaussian
        $display("\n=== Testing GAUSSIAN mode (σ=3.2) ===");
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge clk);
            valid_in = 1;
            rnd_in = { $urandom(), $urandom() };

            valid_in = 0;
            while (!valid_out) @(posedge clk);

            s = sample_out;
            // Check range: |s| <= 32
            
            if (s < 0) abs_s = -s;
            else       abs_s = s;
            if (abs_s > 32) begin
                $display("❌ ERROR: Gaussian sample %d outside [-32,32]!", s);
                $finish;
            end
            if (i < 5) $display("Gaussian sample: %d", s);
            count_gaussian = count_gaussian + 1;
        end

        $display("\n✅ All tests passed!");
        $display("Uniform: %d samples", count_uniform);
        $display("Ternary: %d samples", count_ternary);
        $display("Gaussian: %d samples", count_gaussian);
        $finish;
    end

endmodule