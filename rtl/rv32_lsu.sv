`timescale 1ns / 1ps

module rv32_lsu (
    // From Control & Execute Stage
    input  logic [2:0]  funct3,
    input  logic        mem_wr,
    input  logic [1:0]  addr_offset, // alu_result[1:0]
    input  logic [31:0] rs2_data,    // Raw register data to store

    // To/From BRAM Data Port
    output logic [3:0]  dmem_we,     // 4-bit byte write enable mask
    output logic [31:0] dmem_wdata,  // Shifted/aligned store data
    input  logic [31:0] dmem_rdata,  // Raw 32-bit word read from BRAM

    // To Writeback Mux
    output logic [31:0] lsu_rdata    // Sign/Zero-extended load data for RegFile
);

    logic [7:0]  selected_byte;
    logic [15:0] selected_half;

    // -------------------------------------------------------------------------
    // PART 1: STORE ALIGNMENT & BYTE WRITE-ENABLE GENERATION
    // -------------------------------------------------------------------------
    always_comb begin
        // Default safe values
        dmem_we    = 4'b0000;
        dmem_wdata = 32'd0;

        if (mem_wr) begin
            case (funct3)
                3'b000: begin
                            if (addr_offset == 2'b00 )begin 
                                dmem_we = 4'b0001;
                                dmem_wdata[7:0] = rs2_data[7:0];
                                dmem_wdata[31:8] = 24'b0;

                            end else if ( addr_offset == 2'b01 ) begin
                                dmem_we = 4'b0010;
                                dmem_wdata[7:0] = 8'b0;
                                dmem_wdata[15:8] = rs2_data[7:0];
                                dmem_wdata[31:16] = 16'b0;
                                
                            end else if (addr_offset == 2'b10 ) begin
                                dmem_we = 4'b0100;
                                dmem_wdata[23:16] = rs2_data[7:0];
                                dmem_wdata[15:0] = 16'b0;
                                dmem_wdata[32:24]= 8'b0;
                                
                            end else begin
                                dmem_we = 4'b1000;
                                dmem_wdata[31:24] = rs2_data[7:0];
                                dmem_wdata[23:0] = 24'b0;

                            end


                end
                3'b001: begin
                    //offset of 2 (second half)
                    if(addr_offset[1] == 1'b1)begin 
                        dmem_we = 4'b1100;
                        dmem_wdata[31:16] = rs2_data[15:0];
                        dmem_wdata[15:0] = 16'b0;

                    end
                    //first half
                    else begin 
                        dmem_we = 4'b0011;
                        dmem_wdata[15:0] = rs2_data[15:0];
                        dmem_wdata[31:16] = 16'b0;
                    end

                end
                3'b010: begin
                        dmem_we = 4'b1111;
                        dmem_wdata[31:0] = rs2_data[31:0];

                end
                default: begin
                    dmem_we    = 4'b0000;
                    dmem_wdata = 32'd0;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // PART 2: LOAD BYTE/HALFWORD EXTRACTION & SIGN/ZERO EXTENSION
    // -------------------------------------------------------------------------
    always_comb begin
        // (00 -> [7:0], 01 -> [15:8], 10 -> [23:16], 11 -> [31:24])
        case(addr_offset)
            2'b00:
                selected_byte = dmem_rdata[7:0];
            2'b01:
                selected_byte = dmem_rdata[15:8];
            2'b10:
                selected_byte = dmem_rdata[23:16];
            2'b11:
                selected_byte = dmem_rdata[31:24];
            default:
                selected_byte = 8'd0; 
        endcase
        

        // (0 -> [15:0], 1 -> [31:16])
        selected_half = 16'd0;
        case(addr_offset[1])
            1'b0:
                selected_half = dmem_rdata[15:0];
            1'b1:
                selected_half = dmem_rdata[31:16];
        endcase

        // - 3'b000 (LB):  Sign-extend selected_byte to 32 bits
        // - 3'b001 (LH):  Sign-extend selected_half to 32 bits
        // - 3'b010 (LW):  dmem_rdata
        // - 3'b100 (LBU): Zero-extend selected_byte to 32 bits
        // - 3'b101 (LHU): Zero-extend selected_half to 32 bits
        // - default:      32'd0
        lsu_rdata = 32'd0;
        case(funct3)
            3'b000:begin
                lsu_rdata = {{24{selected_byte[7]}},selected_byte};
            end
            3'b001: begin
                lsu_rdata = {{16{selected_half[15]}},selected_half};
            end
            3'b010:begin
                lsu_rdata = dmem_rdata;
            end
            3'b100:begin
                lsu_rdata = {24'b0,selected_byte};
            end
            3'b101:begin
                lsu_rdata = {16'b0,selected_half};
            end
            default:   lsu_rdata = 32'd0;

        endcase
    end

endmodule
