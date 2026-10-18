`timescale 1ns / 1ps

module rv32_pc (
    input  logic        clk,
    input  logic        rst_n,    // Active-low reset
    input  logic [31:0] pc_next,
    output logic [31:0] pc_q
);


always_ff@(posedge clk) begin

    if(rst_n == 1'b0) begin
        pc_q <= 32'd0;
    end else begin 
        pc_q <= pc_next;
    end


end

endmodule
