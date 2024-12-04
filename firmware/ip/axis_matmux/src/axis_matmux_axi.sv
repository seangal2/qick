module axis_matmux_axi
    #(
        parameter IN_COUNT_WIDTH = 2,  // Number of input bits (1-4), actual inputs = 2^IN_COUNT_WIDTH
        parameter N_OUT = 1            // Number of outputs (1-16)
    )
    (
        // Clock and reset
        input  wire                  aclk,
        input  wire                  aresetn,

        // AXI4-Lite slave interface
        input  wire [7:0]           s_axi_awaddr,
        input  wire [2:0]           s_axi_awprot,
        input  wire                 s_axi_awvalid,
        output wire                 s_axi_awready,
        input  wire [31:0]          s_axi_wdata,
        input  wire [3:0]           s_axi_wstrb,
        input  wire                 s_axi_wvalid,
        output wire                 s_axi_wready,
        output wire [1:0]           s_axi_bresp,
        output wire                 s_axi_bvalid,
        input  wire                 s_axi_bready,
        input  wire [7:0]           s_axi_araddr,
        input  wire [2:0]           s_axi_arprot,
        input  wire                 s_axi_arvalid,
        output wire                 s_axi_arready,
        output wire [31:0]          s_axi_rdata,
        output wire [1:0]           s_axi_rresp,
        output wire                 s_axi_rvalid,
        input  wire                 s_axi_rready,

        // Matrix configuration output
        output wire [4:0]           shift_matrix [0:15][0:15],
        output wire [15:0]          output_enables  // Enable bit for each output
    );

    // Local parameters
    localparam N_IN = 2**IN_COUNT_WIDTH;
    localparam ADDR_BITS = 8;
    localparam REG_CONFIG = 8'h00;    // [31:16] output enables, [15:8] N_OUT, [7:4] reserved, [3:0] IN_COUNT_WIDTH
    localparam REG_MATRIX_BASE = 8'h04;

    // Internal registers
    reg [31:0] axi_regs [0:31];
    reg [31:0] axi_rdata;
    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    reg axi_arready;
    reg axi_rvalid;

    // Configuration registers
    reg [4:0] shift_matrix_reg [0:15][0:15];  // Shift amounts for each input-output pair
    reg [15:0] output_enables_reg;            // Enable bit for each output

    // AXI4-Lite write interface
    always @(posedge aclk) begin
        automatic int row;  // Declare as automatic
        
        if (!aresetn) begin
            axi_awready <= 1'b0;
            axi_wready <= 1'b0;
            axi_bvalid <= 1'b0;
            for (int i = 0; i < 32; i++) begin
                axi_regs[i] <= 32'h0;
            end
            for (int i = 0; i < 16; i++) begin
                for (int j = 0; j < 16; j++) begin
                    shift_matrix_reg[i][j] <= 5'h0;
                end
            end
            output_enables_reg <= 16'h0;  // All outputs disabled by default
        end else begin
            // Write address channel
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
                axi_wready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
                axi_wready <= 1'b0;
            end

            // Write response channel
            if (~axi_bvalid && axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
                axi_bvalid <= 1'b1;
                // Write to registers
                case (s_axi_awaddr[7:2])
                    6'h0: begin // Configuration register
                        if (s_axi_wstrb[2] || s_axi_wstrb[3]) begin
                            output_enables_reg <= s_axi_wdata[31:16] & {{16-N_OUT{1'b0}}, {N_OUT{1'b1}}};
                        end
                    end
                    default: begin
                        if (s_axi_awaddr[7:2] >= 6'h1 && s_axi_awaddr[7:2] < 6'h11) begin
                            // Matrix configuration registers
                            row = (s_axi_awaddr[7:2] - 6'h1);
                            for (int i = 0; i < 4; i++) begin
                                if (s_axi_wstrb[i]) begin
                                    case(i)
                                        0: begin
                                            shift_matrix_reg[row][0] <= s_axi_wdata[4:0];
                                            shift_matrix_reg[row][1] <= s_axi_wdata[12:8];
                                            shift_matrix_reg[row][2] <= s_axi_wdata[20:16];
                                            shift_matrix_reg[row][3] <= s_axi_wdata[28:24];
                                        end
                                        1: begin
                                            shift_matrix_reg[row][4] <= s_axi_wdata[4:0];
                                            shift_matrix_reg[row][5] <= s_axi_wdata[12:8];
                                            shift_matrix_reg[row][6] <= s_axi_wdata[20:16];
                                            shift_matrix_reg[row][7] <= s_axi_wdata[28:24];
                                        end
                                        2: begin
                                            shift_matrix_reg[row][8] <= s_axi_wdata[4:0];
                                            shift_matrix_reg[row][9] <= s_axi_wdata[12:8];
                                            shift_matrix_reg[row][10] <= s_axi_wdata[20:16];
                                            shift_matrix_reg[row][11] <= s_axi_wdata[28:24];
                                        end
                                        3: begin
                                            shift_matrix_reg[row][12] <= s_axi_wdata[4:0];
                                            shift_matrix_reg[row][13] <= s_axi_wdata[12:8];
                                            shift_matrix_reg[row][14] <= s_axi_wdata[20:16];
                                            shift_matrix_reg[row][15] <= s_axi_wdata[28:24];
                                        end
                                    endcase
                                end
                            end
                        end
                    end
                endcase
            end else if (axi_bvalid && s_axi_bready) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite read interface
    always @(posedge aclk) begin
        automatic int row;  // Declare as automatic
        
        if (!aresetn) begin
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rdata <= 32'h0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
            end

            if (~axi_rvalid && axi_arready && s_axi_arvalid) begin
                axi_rvalid <= 1'b1;
                case (s_axi_araddr[7:2])
                    6'h0: axi_rdata <= {output_enables_reg, N_OUT[7:0], 4'h0, IN_COUNT_WIDTH[3:0]};
                    default: begin
                        if (s_axi_araddr[7:2] >= 6'h1 && s_axi_araddr[7:2] < 6'h11) begin
                            row = (s_axi_araddr[7:2] - 6'h1);
                            case(s_axi_araddr[3:2])
                                2'b00: begin
                                    axi_rdata[4:0]   <= shift_matrix_reg[row][0];
                                    axi_rdata[12:8]  <= shift_matrix_reg[row][1];
                                    axi_rdata[20:16] <= shift_matrix_reg[row][2];
                                    axi_rdata[28:24] <= shift_matrix_reg[row][3];
                                    // Clear reserved bits
                                    axi_rdata[7:5]   <= 3'b0;
                                    axi_rdata[15:13] <= 3'b0;
                                    axi_rdata[23:21] <= 3'b0;
                                    axi_rdata[31:29] <= 3'b0;
                                end
                                2'b01: begin
                                    axi_rdata[4:0]   <= shift_matrix_reg[row][4];
                                    axi_rdata[12:8]  <= shift_matrix_reg[row][5];
                                    axi_rdata[20:16] <= shift_matrix_reg[row][6];
                                    axi_rdata[28:24] <= shift_matrix_reg[row][7];
                                    // Clear reserved bits
                                    axi_rdata[7:5]   <= 3'b0;
                                    axi_rdata[15:13] <= 3'b0;
                                    axi_rdata[23:21] <= 3'b0;
                                    axi_rdata[31:29] <= 3'b0;
                                end
                                2'b10: begin
                                    axi_rdata[4:0]   <= shift_matrix_reg[row][8];
                                    axi_rdata[12:8]  <= shift_matrix_reg[row][9];
                                    axi_rdata[20:16] <= shift_matrix_reg[row][10];
                                    axi_rdata[28:24] <= shift_matrix_reg[row][11];
                                    // Clear reserved bits
                                    axi_rdata[7:5]   <= 3'b0;
                                    axi_rdata[15:13] <= 3'b0;
                                    axi_rdata[23:21] <= 3'b0;
                                    axi_rdata[31:29] <= 3'b0;
                                end
                                2'b11: begin
                                    axi_rdata[4:0]   <= shift_matrix_reg[row][12];
                                    axi_rdata[12:8]  <= shift_matrix_reg[row][13];
                                    axi_rdata[20:16] <= shift_matrix_reg[row][14];
                                    axi_rdata[28:24] <= shift_matrix_reg[row][15];
                                    // Clear reserved bits
                                    axi_rdata[7:5]   <= 3'b0;
                                    axi_rdata[15:13] <= 3'b0;
                                    axi_rdata[23:21] <= 3'b0;
                                    axi_rdata[31:29] <= 3'b0;
                                end
                            endcase
                        end else begin
                            axi_rdata <= 32'h0;
                        end
                    end
                endcase
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite output assignments
    assign s_axi_awready = axi_awready;
    assign s_axi_wready = axi_wready;
    assign s_axi_bresp = 2'b00;
    assign s_axi_bvalid = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata = axi_rdata;
    assign s_axi_rresp = 2'b00;
    assign s_axi_rvalid = axi_rvalid;

    // Output matrix assignment
    generate
        for (genvar i = 0; i < 16; i++) begin
            for (genvar j = 0; j < 16; j++) begin
                assign shift_matrix[i][j] = shift_matrix_reg[i][j];
            end
        end
    endgenerate

    // Output enables assignment
    assign output_enables = output_enables_reg;

endmodule 