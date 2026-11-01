module uart_tx #(
    parameter CLOCKS_PER_BIT = 1736 // Default for 50MHz / 115200 Baud
)(
    input  logic       clk,
    input  logic       rst_n,
    
    // Core Interface
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_active,
    output logic       tx_done,
    
    // Physical Output
    output logic       tx_out
);

    typedef enum logic [2:0] {
        IDLE,
        TX_START_BIT,
        TX_DATA_BITS,
        TX_STOP_BIT,
        CLEANUP
    } state_e;

    state_e state_q, state_next;

    logic [15:0] clk_count_q, clk_count_next;
    logic [2:0]  bit_idx_q,   bit_idx_next;
    logic [7:0]  tx_data_q,   tx_data_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q     <= IDLE;
            clk_count_q <= 0;
            bit_idx_q   <= 0;
            tx_data_q   <= 0;
        end else begin
            state_q     <= state_next;
            clk_count_q <= clk_count_next;
            bit_idx_q   <= bit_idx_next;
            tx_data_q   <= tx_data_next;
        end
    end

    always_comb begin
        // Defaults
        state_next     = state_q;
        clk_count_next = clk_count_q;
        bit_idx_next   = bit_idx_q;
        tx_data_next   = tx_data_q;
        
        tx_active      = 1'b1;
        tx_done        = 1'b0;
        tx_out         = 1'b1; // Drive high when idle

        case (state_q)
            IDLE: begin
                tx_active = 1'b0;
                if (tx_start) begin
                    state_next   = TX_START_BIT;
                    tx_data_next = tx_data;
                    clk_count_next = 0;
                end
            end

            TX_START_BIT: begin
                tx_out = 1'b0;
                if (clk_count_q < CLOCKS_PER_BIT - 1) begin
                    clk_count_next = clk_count_q + 1;
                end else begin
                    clk_count_next = 0;
                    state_next     = TX_DATA_BITS;
                    bit_idx_next   = 0;
                end
            end

            TX_DATA_BITS: begin
                tx_out = tx_data_q[bit_idx_q];
                if (clk_count_q < CLOCKS_PER_BIT - 1) begin
                    clk_count_next = clk_count_q + 1;
                end else begin
                    clk_count_next = 0;
                    if (bit_idx_q < 7) begin
                        bit_idx_next = bit_idx_q + 1;
                    end else begin
                        state_next = TX_STOP_BIT;
                    end
                end
            end

            TX_STOP_BIT: begin
                tx_out = 1'b1;
                if (clk_count_q < CLOCKS_PER_BIT - 1) begin
                    clk_count_next = clk_count_q + 1;
                end else begin
                    state_next = CLEANUP;
                end
            end

            CLEANUP: begin
                tx_active = 1'b0;
                tx_done   = 1'b1;
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
    end
endmodule