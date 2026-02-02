`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2026 12:45:14 PM
// Design Name: 
// Module Name: unified
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


module unified #(
        parameter BW_IN  = 64,
        parameter BW_OUT = 48
    )(
        input                           clk,
        input                           rstn,
        input       [1:0]               mode,          // 00: uniform, 01: ternary, 10: gaussian
        input       [BW_IN-1:0]         prng_input,
        output reg  [BW_OUT-1:0]        sample   // Output: prng_input mod q
    );
    
    // Precomputed integer weights for discrete Gaussian (sigma = 3.2)
    // Cumulative weights: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 28, 39, 62, 105, 179, 293, 454, 659, 896, 1145, 1382, 1587, 1748, 1862, 1936, 1979, 2002, 2013, 2018, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041]
    localparam TOTAL_WEIGHT = 11'd2041;
    localparam q = 48'd140736414621701;
   
    
    wire [BW_IN-1:0] PRNG_REG_D;
    
    wire [BW_OUT-1:0] result;
    wire [BW_OUT-1:0] uniform_result;
    reg  [BW_OUT-1:0] ternary_result;
    reg  [BW_OUT-1:0] gaussian_result;
    
    wire [BW_IN-BW_OUT:0] r;
    
    wire [BW_OUT/2-1:0] q_high, q_low;
    
    wire [40-1:0] z0, z1;
    
    wire [15:0] even_bits;
    wire [15:0] odd_bits;
    
    reg [4:0] even_sum;  // max = 16 --> 5 bits
    reg [4:0] odd_sum;   // max = 16 --> 5 bits
    
    reg [4:0] pos_diff;
    
    wire [10:0] mod2041;
    
    reg [31:0] prng_reg;
    
    always @(posedge clk) begin
        if(~rstn) begin
            prng_reg <= 0;
        end else begin
            prng_reg <= prng_input;
        end
    end
    
    
    assign r = prng_input[BW_IN-1:BW_OUT-1];
    assign {q_high, q_low} = q;
    
    
    delay #(.N(1), .BW(BW_IN)) delay_PRNG_REG(
        .clk(clk),
        .rstn(rstn),
        .in(prng_reg),
        .out(PRNG_REG_D)
    );
    
    
    dsp_mul #(.A_WIDTH(24), .B_WIDTH(16)) mul_z1(
        .clk(clk),
        .in1(q_high),
        .in2(r),
        .out(z1)
    );
    
    dsp_mul #(.A_WIDTH(24), .B_WIDTH(16)) mul_z0(
        .clk(clk),
        .in1(q_low),
        .in2(r),
        .out(z0)
    );

    assign mod2041 =  (prng_reg[10:0] >= TOTAL_WEIGHT) ? prng_reg[10:0] - TOTAL_WEIGHT: prng_reg[10:0];
    
    // Extract even and odd bits
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : extract_bits
            assign even_bits[i] = prng_reg[2*i];
            assign odd_bits[i]  = prng_reg[2*i + 1];
        end
    endgenerate
    
    // Combine partial sums (simple linear adder tree)
    always @(*) begin
        integer j;
        even_sum = 0;
        odd_sum  = 0;
        for (j = 0; j < 16; j = j + 1) begin
            even_sum = even_sum + even_bits[j];
            odd_sum  = odd_sum  + odd_bits[j];
        end
        
        if (even_sum > odd_sum) begin
            pos_diff = even_sum - odd_sum;
        end else begin
            pos_diff = 18 - odd_sum + even_sum;
        end
    end
    

    // Efficient modulo-3 for 32-bit input (optimized for synthesis)
    
    // Since pos_diff <= 17 (6 bits), use direct mapping
    reg [1:0] mod3;
    always @(*) begin
        case (pos_diff)
            0,3,6,9,12,15: mod3 = 2'd0;
            1,4,7,10,13,16: mod3 = 2'd1;
            2,5,8,11,14,17: mod3 = 2'd2;
            default: mod3 = 2'd0; // Prevent latch
        endcase
    end
    
    // Map {0,1,2} -> {-1,0,1}
    always @(*) begin
        case (mod3)
            2'd0: ternary_result = -1;  // 2'b11 in 2's complement
            2'd1: ternary_result =  0;  // 2'b00
            2'd2: ternary_result =  1;  // 2'b01
        endcase
    end
    
    assign result = PRNG_REG_D - (z1 << 24) - z0;
    assign uniform_result = (result > q) ? result - q : result;
    
    
    always @(*) begin
        if (mod2041 < 1) begin
            gaussian_result = -31;  // weight = 1  --> indices [0, 0]
        end else if (mod2041 < 2) begin
            gaussian_result = -30;  // weight = 1  --> indices [1, 1]
        end else if (mod2041 < 3) begin
            gaussian_result = -29;  // weight = 1  --> indices [2, 2]
        end else if (mod2041 < 4) begin
            gaussian_result = -28;  // weight = 1  --> indices [3, 3]
        end else if (mod2041 < 5) begin
            gaussian_result = -27;  // weight = 1  --> indices [4, 4]
        end else if (mod2041 < 6) begin
            gaussian_result = -26;  // weight = 1  --> indices [5, 5]
        end else if (mod2041 < 7) begin
            gaussian_result = -25;  // weight = 1  --> indices [6, 6]
        end else if (mod2041 < 8) begin
            gaussian_result = -24;  // weight = 1  --> indices [7, 7]
        end else if (mod2041 < 9) begin
            gaussian_result = -23;  // weight = 1  --> indices [8, 8]
        end else if (mod2041 < 10) begin
            gaussian_result = -22;  // weight = 1  --> indices [9, 9]
        end else if (mod2041 < 11) begin
            gaussian_result = -21;  // weight = 1  --> indices [10, 10]
        end else if (mod2041 < 12) begin
            gaussian_result = -20;  // weight = 1  --> indices [11, 11]
        end else if (mod2041 < 13) begin
            gaussian_result = -19;  // weight = 1  --> indices [12, 12]
        end else if (mod2041 < 14) begin
            gaussian_result = -18;  // weight = 1  --> indices [13, 13]
        end else if (mod2041 < 15) begin
            gaussian_result = -17;  // weight = 1  --> indices [14, 14]
        end else if (mod2041 < 16) begin
            gaussian_result = -16;  // weight = 1  --> indices [15, 15]
        end else if (mod2041 < 17) begin
            gaussian_result = -15;  // weight = 1  --> indices [16, 16]
        end else if (mod2041 < 18) begin
            gaussian_result = -14;  // weight = 1  --> indices [17, 17]
        end else if (mod2041 < 19) begin
            gaussian_result = -13;  // weight = 1  --> indices [18, 18]
        end else if (mod2041 < 20) begin
            gaussian_result = -12;  // weight = 1  --> indices [19, 19]
        end else if (mod2041 < 21) begin
            gaussian_result = -11;  // weight = 1  --> indices [20, 20]
        end else if (mod2041 < 23) begin
            gaussian_result = -10;  // weight = 2  --> indices [21, 22]
        end else if (mod2041 < 28) begin
            gaussian_result = -9;   // weight = 5  --> indices [23, 27]
        end else if (mod2041 < 39) begin
            gaussian_result = -8;   // weight = 11 --> indices [28, 38]
        end else if (mod2041 < 62) begin
            gaussian_result = -7;   // weight = 23 --> indices [39, 61]
        end else if (mod2041 < 105) begin
            gaussian_result = -6;   // weight = 43 --> indices [62, 104]
        end else if (mod2041 < 179) begin
            gaussian_result = -5;   // weight = 74 --> indices [105, 178]
        end else if (mod2041 < 293) begin
            gaussian_result = -4;   // weight = 114 --> indices [179, 292]
        end else if (mod2041 < 454) begin
            gaussian_result = -3;   // weight = 161 --> indices [293, 453]
        end else if (mod2041 < 659) begin
            gaussian_result = -2;   // weight = 205 --> indices [454, 658]
        end else if (mod2041 < 896) begin
            gaussian_result = -1;   // weight = 237 --> indices [659, 895]
        end else if (mod2041 < 1145) begin
            gaussian_result = 0;    // weight = 249 --> indices [896, 1144]
        end else if (mod2041 < 1382) begin
            gaussian_result = 1;    // weight = 237 --> indices [1145, 1381]
        end else if (mod2041 < 1587) begin
            gaussian_result = 2;    // weight = 205 --> indices [1382, 1586]
        end else if (mod2041 < 1748) begin
            gaussian_result = 3;    // weight = 161 --> indices [1587, 1747]
        end else if (mod2041 < 1862) begin
            gaussian_result = 4;    // weight = 114 --> indices [1748, 1861]
        end else if (mod2041 < 1936) begin
            gaussian_result = 5;    // weight = 74  --> indices [1862, 1935]
        end else if (mod2041 < 1979) begin
            gaussian_result = 6;    // weight = 43  --> indices [1936, 1978]
        end else if (mod2041 < 2002) begin
            gaussian_result = 7;    // weight = 23  --> indices [1979, 2001]
        end else if (mod2041 < 2013) begin
            gaussian_result = 8;    // weight = 11  --> indices [2002, 2012]
        end else if (mod2041 < 2018) begin
            gaussian_result = 9;    // weight = 5   --> indices [2013, 2017]
        end else if (mod2041 < 2020) begin
            gaussian_result = 10;   // weight = 2   --> indices [2018, 2019]
        end else if (mod2041 < 2021) begin
            gaussian_result = 11;   // weight = 1   --> indices [2020, 2020]
        end else if (mod2041 < 2022) begin
            gaussian_result = 12;   // weight = 1   --> indices [2021, 2021]
        end else if (mod2041 < 2023) begin
            gaussian_result = 13;   // weight = 1   --> indices [2022, 2022]
        end else if (mod2041 < 2024) begin
            gaussian_result = 14;   // weight = 1   --> indices [2023, 2023]
        end else if (mod2041 < 2025) begin
            gaussian_result = 15;   // weight = 1   --> indices [2024, 2024]
        end else if (mod2041 < 2026) begin
            gaussian_result = 16;   // weight = 1   --> indices [2025, 2025]
        end else if (mod2041 < 2027) begin
            gaussian_result = 17;   // weight = 1   --> indices [2026, 2026]
        end else if (mod2041 < 2028) begin
            gaussian_result = 18;   // weight = 1   --> indices [2027, 2027]
        end else if (mod2041 < 2029) begin
            gaussian_result = 19;   // weight = 1   --> indices [2028, 2028]
        end else if (mod2041 < 2030) begin
            gaussian_result = 20;   // weight = 1   --> indices [2029, 2029]
        end else if (mod2041 < 2031) begin
            gaussian_result = 21;   // weight = 1   --> indices [2030, 2030]
        end else if (mod2041 < 2032) begin
            gaussian_result = 22;   // weight = 1   --> indices [2031, 2031]
        end else if (mod2041 < 2033) begin
            gaussian_result = 23;   // weight = 1   --> indices [2032, 2032]
        end else if (mod2041 < 2034) begin
            gaussian_result = 24;   // weight = 1   --> indices [2033, 2033]
        end else if (mod2041 < 2035) begin
            gaussian_result = 25;   // weight = 1   --> indices [2034, 2034]
        end else if (mod2041 < 2036) begin
            gaussian_result = 26;   // weight = 1   --> indices [2035, 2035]
        end else if (mod2041 < 2037) begin
            gaussian_result = 27;   // weight = 1   --> indices [2036, 2036]
        end else if (mod2041 < 2038) begin
            gaussian_result = 28;   // weight = 1   --> indices [2037, 2037]
        end else if (mod2041 < 2039) begin
            gaussian_result = 29;   // weight = 1   --> indices [2038, 2038]
        end else if (mod2041 < 2040) begin
            gaussian_result = 30;   // weight = 1   --> indices [2039, 2039]
        end else begin  // mod2041 == 2040
            gaussian_result = 31;   // weight = 1   --> indices [2040, 2040]
        end
    end
    
    
    always @(posedge clk) begin
        if (~rstn) begin
            sample <= {BW_OUT{1'b0}};
        end else begin
            case (mode)
                2'b00: sample <= uniform_result;   // Uniform: [0, q-1]
                2'b01: sample <= ternary_result;   // Ternary: {-1, 0, +1}
                2'b10: sample <= gaussian_result;  // Gaussian: [-31, 31]
                default: sample <= uniform_result; // Safe default
            endcase
        end
    end
    
    
endmodule
