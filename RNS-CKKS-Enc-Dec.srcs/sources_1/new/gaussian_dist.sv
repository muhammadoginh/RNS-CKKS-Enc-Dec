`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 08:16:15 PM
// Design Name: 
// Module Name: gaussian_dist
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Discrete Gaussian sampler using CDT (Cumulative Distribution Table)
// Output range: [-31, +31]
// Total weight = 2041
// Uses direct lookup table (LUT) for O(1) sampling
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gaussian_dist (
        input                       clk,            // Clock (for registered output)
        input                       rstn,           // Active-low reset
        input               [31:0]  prng_input,     // 32-bit raw PRNG output
        output reg  signed  [5:0]   sample          // Output: -31 to +31 (6-bit 2's complement)
    );
    
    // Precomputed integer weights for discrete Gaussian (sigma = 3.2)
    // Cumulative weights: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 28, 39, 62, 105, 179, 293, 454, 659, 896, 1145, 1382, 1587, 1748, 1862, 1936, 1979, 2002, 2013, 2018, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031, 2032, 2033, 2034, 2035, 2036, 2037, 2038, 2039, 2040, 2041]
    localparam TOTAL_WEIGHT = 11'd2041;
    
    wire [10:0] mod2041;
    reg [10:0] prng_reg;
    
    always @(posedge clk) begin
        if (~rstn) begin
            prng_reg <= 0;
        end else begin
            prng_reg <= prng_input[10:0];
        end
    end
    
    
    assign mod2041 =  (prng_reg >= TOTAL_WEIGHT) ? prng_reg - TOTAL_WEIGHT: prng_reg;
    
    
    always @(posedge clk) begin
        // Start mod2041 tracking (cumulative sum of weights)
        // WEIGHTS = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 5, 11, 23, 43, ...]
        // CDF = [1, 2, 3, ..., 21, 23, 28, 39, 62, 105, 179, 293, 454, 659, 896, 1145, 
        //        1382, 1587, 1748, 1862, 1936, 1979, 2002, 2013, 2018, 2020, 2021, ..., 2041]
        // Total weight = 2041 (mod2041_d ? [0, 2040])
        
        if (mod2041 < 1) begin
            sample <= -31;  // weight = 1  --> indices [0, 0]
        end else if (mod2041 < 2) begin
            sample <= -30;  // weight = 1  --> indices [1, 1]
        end else if (mod2041 < 3) begin
            sample <= -29;  // weight = 1  --> indices [2, 2]
        end else if (mod2041 < 4) begin
            sample <= -28;  // weight = 1  --> indices [3, 3]
        end else if (mod2041 < 5) begin
            sample <= -27;  // weight = 1  --> indices [4, 4]
        end else if (mod2041 < 6) begin
            sample <= -26;  // weight = 1  --> indices [5, 5]
        end else if (mod2041 < 7) begin
            sample <= -25;  // weight = 1  --> indices [6, 6]
        end else if (mod2041 < 8) begin
            sample <= -24;  // weight = 1  --> indices [7, 7]
        end else if (mod2041 < 9) begin
            sample <= -23;  // weight = 1  --> indices [8, 8]
        end else if (mod2041 < 10) begin
            sample <= -22;  // weight = 1  --> indices [9, 9]
        end else if (mod2041 < 11) begin
            sample <= -21;  // weight = 1  --> indices [10, 10]
        end else if (mod2041 < 12) begin
            sample <= -20;  // weight = 1  --> indices [11, 11]
        end else if (mod2041 < 13) begin
            sample <= -19;  // weight = 1  --> indices [12, 12]
        end else if (mod2041 < 14) begin
            sample <= -18;  // weight = 1  --> indices [13, 13]
        end else if (mod2041 < 15) begin
            sample <= -17;  // weight = 1  --> indices [14, 14]
        end else if (mod2041 < 16) begin
            sample <= -16;  // weight = 1  --> indices [15, 15]
        end else if (mod2041 < 17) begin
            sample <= -15;  // weight = 1  --> indices [16, 16]
        end else if (mod2041 < 18) begin
            sample <= -14;  // weight = 1  --> indices [17, 17]
        end else if (mod2041 < 19) begin
            sample <= -13;  // weight = 1  --> indices [18, 18]
        end else if (mod2041 < 20) begin
            sample <= -12;  // weight = 1  --> indices [19, 19]
        end else if (mod2041 < 21) begin
            sample <= -11;  // weight = 1  --> indices [20, 20]
        end else if (mod2041 < 23) begin
            sample <= -10;  // weight = 2  --> indices [21, 22]
        end else if (mod2041 < 28) begin
            sample <= -9;   // weight = 5  --> indices [23, 27]
        end else if (mod2041 < 39) begin
            sample <= -8;   // weight = 11 --> indices [28, 38]
        end else if (mod2041 < 62) begin
            sample <= -7;   // weight = 23 --> indices [39, 61]
        end else if (mod2041 < 105) begin
            sample <= -6;   // weight = 43 --> indices [62, 104]
        end else if (mod2041 < 179) begin
            sample <= -5;   // weight = 74 --> indices [105, 178]
        end else if (mod2041 < 293) begin
            sample <= -4;   // weight = 114 --> indices [179, 292]
        end else if (mod2041 < 454) begin
            sample <= -3;   // weight = 161 --> indices [293, 453]
        end else if (mod2041 < 659) begin
            sample <= -2;   // weight = 205 --> indices [454, 658]
        end else if (mod2041 < 896) begin
            sample <= -1;   // weight = 237 --> indices [659, 895]
        end else if (mod2041 < 1145) begin
            sample <= 0;    // weight = 249 --> indices [896, 1144]
        end else if (mod2041 < 1382) begin
            sample <= 1;    // weight = 237 --> indices [1145, 1381]
        end else if (mod2041 < 1587) begin
            sample <= 2;    // weight = 205 --> indices [1382, 1586]
        end else if (mod2041 < 1748) begin
            sample <= 3;    // weight = 161 --> indices [1587, 1747]
        end else if (mod2041 < 1862) begin
            sample <= 4;    // weight = 114 --> indices [1748, 1861]
        end else if (mod2041 < 1936) begin
            sample <= 5;    // weight = 74  --> indices [1862, 1935]
        end else if (mod2041 < 1979) begin
            sample <= 6;    // weight = 43  --> indices [1936, 1978]
        end else if (mod2041 < 2002) begin
            sample <= 7;    // weight = 23  --> indices [1979, 2001]
        end else if (mod2041 < 2013) begin
            sample <= 8;    // weight = 11  --> indices [2002, 2012]
        end else if (mod2041 < 2018) begin
            sample <= 9;    // weight = 5   --> indices [2013, 2017]
        end else if (mod2041 < 2020) begin
            sample <= 10;   // weight = 2   --> indices [2018, 2019]
        end else if (mod2041 < 2021) begin
            sample <= 11;   // weight = 1   --> indices [2020, 2020]
        end else if (mod2041 < 2022) begin
            sample <= 12;   // weight = 1   --> indices [2021, 2021]
        end else if (mod2041 < 2023) begin
            sample <= 13;   // weight = 1   --> indices [2022, 2022]
        end else if (mod2041 < 2024) begin
            sample <= 14;   // weight = 1   --> indices [2023, 2023]
        end else if (mod2041 < 2025) begin
            sample <= 15;   // weight = 1   --> indices [2024, 2024]
        end else if (mod2041 < 2026) begin
            sample <= 16;   // weight = 1   --> indices [2025, 2025]
        end else if (mod2041 < 2027) begin
            sample <= 17;   // weight = 1   --> indices [2026, 2026]
        end else if (mod2041 < 2028) begin
            sample <= 18;   // weight = 1   --> indices [2027, 2027]
        end else if (mod2041 < 2029) begin
            sample <= 19;   // weight = 1   --> indices [2028, 2028]
        end else if (mod2041 < 2030) begin
            sample <= 20;   // weight = 1   --> indices [2029, 2029]
        end else if (mod2041 < 2031) begin
            sample <= 21;   // weight = 1   --> indices [2030, 2030]
        end else if (mod2041 < 2032) begin
            sample <= 22;   // weight = 1   --> indices [2031, 2031]
        end else if (mod2041 < 2033) begin
            sample <= 23;   // weight = 1   --> indices [2032, 2032]
        end else if (mod2041 < 2034) begin
            sample <= 24;   // weight = 1   --> indices [2033, 2033]
        end else if (mod2041 < 2035) begin
            sample <= 25;   // weight = 1   --> indices [2034, 2034]
        end else if (mod2041 < 2036) begin
            sample <= 26;   // weight = 1   --> indices [2035, 2035]
        end else if (mod2041 < 2037) begin
            sample <= 27;   // weight = 1   --> indices [2036, 2036]
        end else if (mod2041 < 2038) begin
            sample <= 28;   // weight = 1   --> indices [2037, 2037]
        end else if (mod2041 < 2039) begin
            sample <= 29;   // weight = 1   --> indices [2038, 2038]
        end else if (mod2041 < 2040) begin
            sample <= 30;   // weight = 1   --> indices [2039, 2039]
        end else begin  // mod2041 == 2040
            sample <= 31;   // weight = 1   --> indices [2040, 2040]
        end
    end

endmodule