/* Vedant Kelkar - vkelkar     Manas Kulkarni - manask */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module divider_unsigned_pipelined (
    input wire clk, rst,
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output reg [31:0] o_remainder,
    output reg [31:0] o_quotient
);

    reg [31:0] dividend_reg;
    reg [31:0] quotient_reg;
    reg [31:0] remainder_reg;
    
    // Stage 1
    wire [31:0] dividend_stage1 [0:16];
    wire [31:0] quotient_stage1 [0:16];
    wire [31:0] remainder_stage1 [0:16];
    wire [31:0] dividend_stage2 [0:16];
    wire [31:0] quotient_stage2 [0:16];
    wire [31:0] remainder_stage2 [0:16];
    
    // Stage 1: Connect the first set of inputs to the external inputs
    assign dividend_stage1[0] = {16'b0, i_dividend[15:0]};
    assign quotient_stage1[0] = {16'b0, 16'b0}; // Corrected assignment size
    assign remainder_stage1[0] = 32'b0;
    
    // Instantiate 16 divu_1iter modules for Stage 1
    generate
        for (genvar i=0; i < 16; i++) begin : stage1_div
            divu_1iter div_iter (
                .i_dividend(dividend_stage1[i]),
                .i_divisor(i_divisor),
                .i_remainder(remainder_stage1[i]),
                .i_quotient(quotient_stage1[i]),
                .o_dividend(dividend_stage1[i+1]),
                .o_remainder(remainder_stage1[i+1]),
                .o_quotient(quotient_stage1[i+1])
            );
        end
    endgenerate
    
    // Stage 1: Connect the last set of outputs to the stage 2 inputs
    assign dividend_stage2[0] = dividend_stage1[16];
    assign quotient_stage2[0] = quotient_stage1[16];
    assign remainder_stage2[0] = remainder_stage1[16];
    
    // Instantiate 16 divu_1iter modules for Stage 2
    generate
        for (genvar i=0; i < 16; i++) begin : stage2_div
            divu_1iter div_iter (
                .i_dividend(dividend_stage2[i]),
                .i_divisor(i_divisor),
                .i_remainder(remainder_stage2[i]),
                .i_quotient(quotient_stage2[i]),
                .o_dividend(dividend_stage2[i+1]),
                .o_remainder(remainder_stage2[i+1]),
                .o_quotient(quotient_stage2[i+1])
            );
        end
    endgenerate

    // assign o_remainder = remainder_stage2[16];
    // assign o_quotient  = quotient_stage2[16];
    
    // Connect the last set of outputs of stage 2 to the registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dividend_reg <= 32'b0;
            quotient_reg <= 32'b0;
            remainder_reg <= 32'b0;
        end else begin
            dividend_reg <= dividend_stage2[16];
            quotient_reg <= quotient_stage2[16];
            remainder_reg <= remainder_stage2[16];
        end
    end
    
    // Output registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_remainder <= 32'b0;
            o_quotient <= 32'b0;
        end else begin
            o_remainder <= remainder_reg;
            o_quotient <= quotient_reg;
        end
    end

endmodule


module divu_1iter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);

    
    logic [31:0] t_remainder;
    logic [31:0] t1_remainder;
    logic [31:0] quotient;
    logic [31:0] shifted_dividend;

    always_comb begin
        assign t_remainder = {i_remainder[30:0], i_dividend[31]};
        assign shifted_dividend = i_dividend << 1;

        // Update quotient conditionally
        assign quotient = (t_remainder < i_divisor) ? (i_quotient << 1) : ({i_quotient[30:0], 1'b1});
        assign t1_remainder = (t_remainder < i_divisor) ? t_remainder : t_remainder - i_divisor;
    end

    assign o_dividend = shifted_dividend;
    assign o_remainder = t1_remainder;
    assign o_quotient = quotient;
endmodule
