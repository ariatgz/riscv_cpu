module rv32_system (
    input  logic sys_clk_p,  
    input  logic sys_clk_n,  
    input  logic rst_n,
    output logic uart_tx_out ,
    output logic led_out 
);

    // Internal wires (NO INPUT PORTS HERE)
    logic clk; 
    logic [31:0] imem_addr, imem_rdata;
    logic        dmem_wr;
    logic [3:0]  dmem_we;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata, ram_rdata;
    
    localparam UART_TX_ADDR = 32'h8000_0000;

    // 1. Differential Clock Buffer
    IBUFGDS u_ibufgds (
        .I  (sys_clk_p),
        .IB (sys_clk_n),
        .O  (clk)
    );

    // 2. The RISC-V CPU
    
    rv32_core u_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_wr    (dmem_wr),
        .dmem_we    (dmem_we),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_rdata (dmem_rdata)
    );

    // 3. Main System Memory
    rv32_memory #(
        .INIT_FILE ("C:/AMD/riscv_core/rtl/program.mem")
    ) u_ram (
        .clk        (clk),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_wr    (dmem_wr && (dmem_addr != UART_TX_ADDR)),
        .dmem_we    (dmem_we),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_rdata (ram_rdata)
    );

    // 4. Memory-Mapped I/O (MMIO) Decoder
    logic       uart_we;
    logic       uart_active, uart_done, uart_start;
    logic [7:0] uart_data;

    assign uart_we = dmem_wr && (dmem_addr == UART_TX_ADDR);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_start <= 1'b0;
            uart_data  <= 8'h00;
        end else begin
            if (uart_we && !uart_active) begin
                uart_start <= 1'b1;
                uart_data  <= dmem_wdata[7:0];
            end else begin
                uart_start <= 1'b0;
            end
        end
    end

    assign dmem_rdata = ram_rdata;

    // 5. The UART Transmitter (200 MHz / 115200 Baud)
    uart_tx #(
        .CLOCKS_PER_BIT (1736) 
    ) u_uart (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_start  (uart_start),
        .tx_data   (uart_data),
        .tx_active (uart_active),
        .tx_done   (uart_done),
        .tx_out    (uart_tx_out)
    );

    logic [27:0] heartbeat;
    always_ff @(posedge clk) heartbeat <= heartbeat + 1;
    assign led_out = heartbeat[27];

endmodule