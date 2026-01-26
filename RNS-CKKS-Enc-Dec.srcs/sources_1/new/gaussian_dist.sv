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
// Discrete Gaussian Sampler (sigma = 2.5-3.0)
// Output range: [-10, +10]
// Total weight = 997
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
        input                       clk,          // Clock (for registered output)
        input                       rstn,        // Active-low reset
        input               [31:0]  prng_input,   // 32-bit raw PRNG output
        output reg  signed  [4:0]   sample // Output: -10 to +10 (5-bit 2's complement)
    );
    
    // Precomputed integer weights for discrete Gaussian (sigma = 3.19)
    // WEIGHTS = [1, 2, 5, 11, 21, 37, 57, 80, 103, 119, 125, 119, 103, 80, 57, 37, 21, 11, 5, 2, 1]
    // Cumulative weights: [1, 3, 8, 19, 40, 77, 134, 214, 317, 436, 561, 680, 783, 863, 920, 957, 978, 989, 994, 996, 997]
    localparam TOTAL_WEIGHT = 10'd997;
    
    wire [9:0] mod997, mod997_d;
    reg [9:0] prng_reg;
    
    always @(posedge clk) begin
        if (~rstn) begin
            prng_reg <= 0;
        end else begin
            prng_reg <= prng_input[9:0];
        end
    end
    
    
    assign mod997 =  (prng_reg >= TOTAL_WEIGHT) ? prng_reg - TOTAL_WEIGHT: prng_reg;
    
    delay #(.N(1), .BW(10)) delay_mod997(
        .clk(clk),
        .rstn(rstn),
        .in(mod997),
        .out(mod997_d)
    );
    
//    wire signed [4:0] sample_temp = 
//    (mod997_d < 1)   ? -10 :
//    (mod997_d < 3)   ? -9  :
//    (mod997_d < 8)   ? -8  :
//    (mod997_d < 19)  ? -7  :
//    (mod997_d < 40)  ? -6  :
//    (mod997_d < 77)  ? -5  :
//    (mod997_d < 134) ? -4  :
//    (mod997_d < 214) ? -3  :
//    (mod997_d < 317) ? -2  :
//    (mod997_d < 436) ? -1  :
//    (mod997_d < 561) ? 0   :
//    (mod997_d < 680) ? 1   :
//    (mod997_d < 783) ? 2   :
//    (mod997_d < 863) ? 3   :
//    (mod997_d < 920) ? 4   :
//    (mod997_d < 957) ? 5   :
//    (mod997_d < 978) ? 6   :
//    (mod997_d < 989) ? 7   :
//    (mod997_d < 994) ? 8   :
//    (mod997_d < 996) ? 9   :
//                      10;
                      
//     always @(posedge clk) begin
//        if (~rstn) begin
//            sample <= 0;
//        end else begin
//            sample <= sample_temp;
//        end
//     end
    
    
    always @(posedge clk) begin
        // Start mod997 tracking (cumulative sum of weights)
        // WEIGHTS = [1, 2, 5, 11, 21, 37, 57, 80, 103, 119, 125, ...]
        if (mod997_d < 1) begin
            sample <= -10;  // weight = 1 --> indices [0, 0]
        end else if (mod997_d < 3) begin
            sample <= -9;   // weight = 2 --> indices [1, 2]
        end else if (mod997_d < 8) begin
            sample <= -8;   // weight = 5 --> indices [3, 7]
        end else if (mod997_d < 19) begin
            sample <= -7;   // weight = 11 --> indices [8, 18]
        end else if (mod997_d < 40) begin
            sample <= -6;   // weight = 21 --> indices [19, 39]
        end else if (mod997_d < 77) begin
            sample <= -5;   // weight = 37 --> indices [40, 76]
        end else if (mod997_d < 134) begin
            sample <= -4;   // weight = 57 --> indices [77, 133]
        end else if (mod997_d < 214) begin
            sample <= -3;   // weight = 80 --> indices [134, 213]
        end else if (mod997_d < 317) begin
            sample <= -2;   // weight = 103 --> indices [214, 316]
        end else if (mod997_d < 436) begin
            sample <= -1;   // weight = 119 --> indices [317, 435]
        end else if (mod997_d < 561) begin
            sample <= 0;    // weight = 125 --> indices [436, 560]
        end else if (mod997_d < 680) begin
            sample <= 1;    // weight = 119 --> indices [561, 679]
        end else if (mod997_d < 783) begin
            sample <= 2;    // weight = 103 --> indices [680, 782]
        end else if (mod997_d < 863) begin
            sample <= 3;    // weight = 80 --> indices [783, 862]
        end else if (mod997_d < 920) begin
            sample <= 4;    // weight = 57 --> indices [863, 919]
        end else if (mod997_d < 957) begin
            sample <= 5;    // weight = 37 --> indices [920, 956]
        end else if (mod997_d < 978) begin
            sample <= 6;    // weight = 21 --> indices [957, 977]
        end else if (mod997_d < 989) begin
            sample <= 7;    // weight = 11 --> indices [978, 988]
        end else if (mod997_d < 994) begin
            sample <= 8;    // weight = 5 --> indices [989, 993]
        end else if (mod997_d < 996) begin
            sample <= 9;    // weight = 2 --> indices [994, 995]
        end else begin
            sample <= 10;   // weight = 1 --> mod997 [996]
        end
    end

endmodule