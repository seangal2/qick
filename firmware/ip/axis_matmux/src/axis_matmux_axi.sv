module axis_matmux_axi
    #(
        parameter IN_COUNT_WIDTH = 2,  // Number of input bits (1-4), actual inputs = 2^IN_COUNT_WIDTH
        parameter N_OUT = 1            // Number of outputs (1-16)
    )
    (
        // Clock and reset
        input  wire                  axi_aclk,
        input  wire                  axi_aresetn,

        // AXI4-Lite slave interface
        
        // "Specify write address"
        input  wire [8:0]           s_axi_awaddr,
        input  wire [2:0]           s_axi_awprot,
        input  wire                 s_axi_awvalid,
        output wire                 s_axi_awready,

        // "Write Data"
        input  wire [31:0]          s_axi_wdata,
        input  wire [3:0]           s_axi_wstrb,
        input  wire                 s_axi_wvalid,
        output wire                 s_axi_wready,

        // "Write Response"
        output wire [1:0]           s_axi_bresp,
        output wire                 s_axi_bvalid,
        input  wire                 s_axi_bready,

        // "Specify read address"
        input  wire [8:0]           s_axi_araddr,
        input  wire [2:0]           s_axi_arprot,
        input  wire                 s_axi_arvalid,
        output wire                 s_axi_arready,

        // "Read Data"
        output wire [31:0]          s_axi_rdata,
        output wire [1:0]           s_axi_rresp,
        output wire                 s_axi_rvalid,
        input  wire                 s_axi_rready,

        // Matrix configuration output
        output wire [4:0]           shift_matrix [0:N_OUT-1][0:2**IN_COUNT_WIDTH-1],
        output wire [N_OUT-1:0]     output_enables  // Enable bit for each output
    );

    // Local parameters
    localparam N_IN = 2**IN_COUNT_WIDTH;
    localparam ADDR_LSB = 2;  // For 32-bit data
    localparam OPT_MEM_ADDR_BITS = 8;

    // Internal registers for AXI interface
    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    reg [1:0] axi_bresp;
    reg axi_arready;
    reg axi_rvalid;
    reg [31:0] axi_rdata;
    reg [8:0] axi_awaddr;
    reg [8:0] axi_araddr;
    reg axi_arvalid;
    reg aw_en;  // Write address channel control

    // Configuration registers
    reg [4:0] shift_matrix_reg [0:15][0:15];
    reg [15:0] output_enables_reg;


    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (axi_awready == 1'b0 && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                axi_awready <= 1'b1;  // Slave is ready to accept write address when both valid
                aw_en <= 1'b0;
            end else if (s_axi_bready && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_awaddr <= '0;
        end else begin
            if (axi_awready == 1'b0 && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                axi_awaddr <= s_axi_awaddr;  // Write Address latching
            end
        end
    end

    // Write data channel control
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (axi_wready == 1'b0 && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                axi_wready <= 1'b1;  // Slave is ready to accept write data when both valid
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Write enable signal - exactly like VHDL
    wire slv_reg_wren;
    assign slv_reg_wren = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid;

    // Write registers
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            output_enables_reg <= '0;
            for (int i = 0; i < 16; i++)
                for (int j = 0; j < 16; j++)
                    shift_matrix_reg[i][j] <= '0;
        end else begin            
            if (slv_reg_wren) begin  // Use the same write enable as VHDL
                if (axi_awaddr[8]) begin
                    if (s_axi_wstrb[2] || s_axi_wstrb[3])
                        output_enables_reg <= s_axi_wdata[31:16] & {{16-N_OUT{1'b0}}, {N_OUT{1'b1}}};
                end else begin
                    automatic logic [3:0] row = axi_awaddr[7:4];
                    automatic logic [1:0] col = axi_awaddr[3:2];
                    
                    if (s_axi_wstrb[0]) shift_matrix_reg[row][col*4+0] <= s_axi_wdata[4:0];
                    if (s_axi_wstrb[1]) shift_matrix_reg[row][col*4+1] <= s_axi_wdata[12:8];
                    if (s_axi_wstrb[2]) shift_matrix_reg[row][col*4+2] <= s_axi_wdata[20:16];
                    if (s_axi_wstrb[3]) shift_matrix_reg[row][col*4+3] <= s_axi_wdata[28:24];
                end
            end
        end
    end

    // Write response channel
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp <= 2'b00;
        end else begin
            if (slv_reg_wren) begin  // Assert bvalid when write happens
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b00;
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // Read address channel control
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr <= '0;
            axi_arvalid <= 1'b0;  // Initialize arvalid
        end else begin
            if (!axi_arready && s_axi_arvalid) begin
                // Accept read address
                axi_arready <= 1'b1;
                axi_araddr <= s_axi_araddr;
                axi_arvalid <= 1'b1;  // Set valid for data phase
            end else begin
                axi_arready <= 1'b0;
                if (axi_rvalid && s_axi_rready) begin
                    axi_arvalid <= 1'b0;  // Clear valid after data is read
                end
            end
        end
    end

    // Read data channel control
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rdata <= '0;
        end else begin
            if (axi_arvalid && !axi_rvalid) begin
                axi_rvalid <= 1'b1;
                
                // Read data multiplexing
                if (axi_araddr[8]) begin  // Configuration register at 0x100
                    axi_rdata <= {output_enables_reg, N_OUT[7:0], 4'h0, IN_COUNT_WIDTH[3:0]};
                end else begin  // Matrix configuration
                    automatic logic [3:0] row = axi_araddr[7:4];
                    automatic logic [1:0] col = axi_araddr[3:2];

                    // Pack 4 shift values into one 32-bit word
                    axi_rdata[4:0]   <= shift_matrix_reg[row][col*4 + 0];
                    axi_rdata[12:8]  <= shift_matrix_reg[row][col*4 + 1];
                    axi_rdata[20:16] <= shift_matrix_reg[row][col*4 + 2];
                    axi_rdata[28:24] <= shift_matrix_reg[row][col*4 + 3];
                    // Clear reserved bits
                    axi_rdata[7:5]   <= 3'b0;
                    axi_rdata[15:13] <= 3'b0;
                    axi_rdata[23:21] <= 3'b0;
                    axi_rdata[31:29] <= 3'b0;
                end
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite output assignments
    assign s_axi_awready = axi_awready;
    assign s_axi_wready = axi_wready;
    assign s_axi_bresp = axi_bresp;
    assign s_axi_bvalid = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata = axi_rdata;
    assign s_axi_rresp = 2'b00;
    assign s_axi_rvalid = axi_rvalid;

    // Output matrix assignment - only use N_OUTxN_IN matrix
    generate
        for (genvar i = 0; i < N_OUT; i++) begin
            for (genvar j = 0; j < N_IN; j++) begin
                assign shift_matrix[i][j] = shift_matrix_reg[i][j];
            end
            
            // Output enables assignment
            assign output_enables[i] = output_enables_reg[i];
        end
    endgenerate


endmodule 