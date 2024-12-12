module axis_matmux
    #(
        parameter IN_COUNT_WIDTH = 1,  // Number of input bits (1-4), actual inputs = 2^IN_COUNT_WIDTH
        parameter N_OUT = 2,           // Number of outputs (1-16)
        parameter IN_WIDTH = 16,       // Width of each input in bits
        parameter N_PARALLELISM = 2,  // Number of inputs in parallel
        parameter STAGE_DELAY = 1      // Number of pipeline stages between each adder level
    )
    (
        // Clock and reset
        input  wire                  aclk,
        input  wire                  aresetn,

        // AXI4-Lite slave interface
        input  wire [8:0]           s_axi_awaddr,
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
        input  wire [8:0]           s_axi_araddr,
        input  wire [2:0]           s_axi_arprot,
        input  wire                 s_axi_arvalid,
        output wire                 s_axi_arready,
        output wire [31:0]          s_axi_rdata,
        output wire [1:0]           s_axi_rresp,
        output wire                 s_axi_rvalid,
        input  wire                 s_axi_rready,

        // AXIS Slave interfaces (up to 16 inputs)
        input  wire                 s00_axis_tvalid,
        output logic               s00_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s00_axis_tdata,
        
        input  wire                 s01_axis_tvalid,
        output logic               s01_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s01_axis_tdata,
        
        input  wire                 s02_axis_tvalid,
        output logic               s02_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s02_axis_tdata,
        
        input  wire                 s03_axis_tvalid,
        output logic               s03_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s03_axis_tdata,
        
        input  wire                 s04_axis_tvalid,
        output logic               s04_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s04_axis_tdata,
        
        input  wire                 s05_axis_tvalid,
        output logic               s05_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s05_axis_tdata,
        
        input  wire                 s06_axis_tvalid,
        output logic               s06_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s06_axis_tdata,
        
        input  wire                 s07_axis_tvalid,
        output logic               s07_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s07_axis_tdata,
        
        input  wire                 s08_axis_tvalid,
        output logic               s08_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s08_axis_tdata,
        
        input  wire                 s09_axis_tvalid,
        output logic               s09_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s09_axis_tdata,
        
        input  wire                 s10_axis_tvalid,
        output logic               s10_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s10_axis_tdata,
        
        input  wire                 s11_axis_tvalid,
        output logic               s11_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s11_axis_tdata,
        
        input  wire                 s12_axis_tvalid,
        output logic               s12_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s12_axis_tdata,
        
        input  wire                 s13_axis_tvalid,
        output logic               s13_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s13_axis_tdata,
        
        input  wire                 s14_axis_tvalid,
        output logic               s14_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s14_axis_tdata,
        
        input  wire                 s15_axis_tvalid,
        output logic               s15_axis_tready,
        input  wire [N_PARALLELISM*IN_WIDTH-1:0]  s15_axis_tdata,

        // AXIS Master interfaces (up to 16 outputs)
        output logic                 m00_axis_tvalid,
        input  wire                 m00_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m00_axis_tdata,
        
        output logic                 m01_axis_tvalid,
        input  wire                 m01_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m01_axis_tdata,
        
        output logic                 m02_axis_tvalid,
        input  wire                 m02_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m02_axis_tdata,
        
        output logic                 m03_axis_tvalid,
        input  wire                 m03_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m03_axis_tdata,
        
        output logic                 m04_axis_tvalid,
        input  wire                 m04_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m04_axis_tdata,
        
        output logic                 m05_axis_tvalid,
        input  wire                 m05_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m05_axis_tdata,
        
        output logic                 m06_axis_tvalid,
        input  wire                 m06_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m06_axis_tdata,
        
        output logic                 m07_axis_tvalid,
        input  wire                 m07_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m07_axis_tdata,
        
        output logic                 m08_axis_tvalid,
        input  wire                 m08_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m08_axis_tdata,
        
        output logic                 m09_axis_tvalid,
        input  wire                 m09_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m09_axis_tdata,
        
        output logic                 m10_axis_tvalid,
        input  wire                 m10_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m10_axis_tdata,
        
        output logic                 m11_axis_tvalid,
        input  wire                 m11_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m11_axis_tdata,
        
        output logic                 m12_axis_tvalid,
        input  wire                 m12_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m12_axis_tdata,
        
        output logic                 m13_axis_tvalid,
        input  wire                 m13_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m13_axis_tdata,
        
        output logic                 m14_axis_tvalid,
        input  wire                 m14_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m14_axis_tdata,
        
        output logic                 m15_axis_tvalid,
        input  wire                 m15_axis_tready,
        output logic [N_PARALLELISM*IN_WIDTH-1:0]  m15_axis_tdata
    );

    // Local parameters
    localparam N_IN = 2**IN_COUNT_WIDTH;

    // Interconnect signals
    wire [4:0] shift_matrix [0:N_OUT-1][0:N_IN-1];
    wire [N_OUT-1:0] output_enables;

    // Instantiate AXI4-Lite slave interface
    axis_matmux_axi #(
        .IN_COUNT_WIDTH(IN_COUNT_WIDTH),
        .N_OUT(N_OUT)
    ) axi_slave (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .shift_matrix(shift_matrix),
        .output_enables(output_enables)
    );

    // // Configuration matrix
    // (* keep = "true" *) reg [4:0] shift_matrix2 [0:N_OUT-1][0:N_IN-1];
    // (* keep = "true" *) wire [N_OUT-1:0] output_enables2;

    // assign output_enables2 = 2'b11;
    // always @(posedge aclk) begin
    //     for (int i = 0; i < N_OUT; i++) begin
    //         for (int j = 0; j < N_IN; j++) begin
    //             shift_matrix2[i][j] = 0;
    //         end
    //     end
    // end

    // Add pipeline registers for shift_matrix and output_enables to help with hold times due to high fanout
    reg [4:0] shift_matrix_r1 [0:N_OUT-1][0:N_IN-1];
    reg [4:0] shift_matrix_r2 [0:N_OUT-1][0:N_IN-1];
    reg [4:0] shift_matrix_r3 [0:N_OUT-1][0:N_IN-1];
    reg [4:0] shift_matrix_r4 [0:N_OUT-1][0:N_IN-1];
    
    reg [N_OUT-1:0] output_enables_r1;
    reg [N_OUT-1:0] output_enables_r2;
    reg [N_OUT-1:0] output_enables_r3;
    reg [N_OUT-1:0] output_enables_r4;

    always @(posedge aclk) begin
        if (!aresetn) begin
            shift_matrix_r1 <= '{default: '{default: 0}};
            shift_matrix_r2 <= '{default: '{default: 0}};
            shift_matrix_r3 <= '{default: '{default: 0}};
            shift_matrix_r4 <= '{default: '{default: 0}};
            output_enables_r1 <= 0;
            output_enables_r2 <= 0;
            output_enables_r3 <= 0;
            output_enables_r4 <= 0;
        end else begin
            shift_matrix_r1 <= shift_matrix;
            output_enables_r1 <= output_enables;

            shift_matrix_r2 <= shift_matrix_r1;
            output_enables_r2 <= output_enables_r1;

            shift_matrix_r3 <= shift_matrix_r2;
            output_enables_r3 <= output_enables_r2;

            shift_matrix_r4 <= shift_matrix_r3;
            output_enables_r4 <= output_enables_r3;
        end
    end

    
    // Pack input signals into arrays for the core module
    wire [15:0] s_axis_tvalid;
    wire [15:0] s_axis_tready;
    wire [15:0][N_PARALLELISM*IN_WIDTH-1:0] s_axis_tdata;

    assign s_axis_tvalid = {s15_axis_tvalid, s14_axis_tvalid, s13_axis_tvalid, s12_axis_tvalid,
                    s11_axis_tvalid, s10_axis_tvalid, s09_axis_tvalid, s08_axis_tvalid,
                    s07_axis_tvalid, s06_axis_tvalid, s05_axis_tvalid, s04_axis_tvalid,
                    s03_axis_tvalid, s02_axis_tvalid, s01_axis_tvalid, s00_axis_tvalid};

    assign s_axis_tready = {s15_axis_tready, s14_axis_tready, s13_axis_tready, s12_axis_tready,
                 s11_axis_tready, s10_axis_tready, s09_axis_tready, s08_axis_tready,
                 s07_axis_tready, s06_axis_tready, s05_axis_tready, s04_axis_tready,
                 s03_axis_tready, s02_axis_tready, s01_axis_tready, s00_axis_tready};

    assign s_axis_tdata = {s15_axis_tdata, s14_axis_tdata, s13_axis_tdata, s12_axis_tdata,
                    s11_axis_tdata, s10_axis_tdata, s09_axis_tdata, s08_axis_tdata,
                    s07_axis_tdata, s06_axis_tdata, s05_axis_tdata, s04_axis_tdata,
                    s03_axis_tdata, s02_axis_tdata, s01_axis_tdata, s00_axis_tdata};
            
    wire [15:0] m_axis_tvalid;
    wire [15:0] m_axis_tready;
    wire [15:0][N_PARALLELISM*IN_WIDTH-1:0] m_axis_tdata;

    assign m_axis_tvalid = {m15_axis_tvalid, m14_axis_tvalid, m13_axis_tvalid, m12_axis_tvalid,
                    m11_axis_tvalid, m10_axis_tvalid, m09_axis_tvalid, m08_axis_tvalid,
                    m07_axis_tvalid, m06_axis_tvalid, m05_axis_tvalid, m04_axis_tvalid,
                    m03_axis_tvalid, m02_axis_tvalid, m01_axis_tvalid, m00_axis_tvalid};

    assign m_axis_tready = {m15_axis_tready, m14_axis_tready, m13_axis_tready, m12_axis_tready,
                    m11_axis_tready, m10_axis_tready, m09_axis_tready, m08_axis_tready,
                    m07_axis_tready, m06_axis_tready, m05_axis_tready, m04_axis_tready,
                    m03_axis_tready, m02_axis_tready, m01_axis_tready, m00_axis_tready};

    assign m_axis_tdata = {m15_axis_tdata, m14_axis_tdata, m13_axis_tdata, m12_axis_tdata,
                    m11_axis_tdata, m10_axis_tdata, m09_axis_tdata, m08_axis_tdata,
                    m07_axis_tdata, m06_axis_tdata, m05_axis_tdata, m04_axis_tdata,
                    m03_axis_tdata, m02_axis_tdata, m01_axis_tdata, m00_axis_tdata};

    logic [N_IN-1:0][N_PARALLELISM-1:0] s_axis_tready_core;
    logic [N_OUT-1:0][N_PARALLELISM-1:0] m_axis_tvalid_core;

    genvar i;
    generate
        for (i = 0; i < N_PARALLELISM; i++) begin : gen_matmux_cores
            // Pack output signals into arrays for the core module
            wire [15:0][IN_WIDTH-1:0] s_axis_tdata_core;
            wire [15:0][IN_WIDTH-1:0] m_axis_tdata_core;

            // Change these assignments to be unidirectional
            for (genvar j = 0; j < 16; j++) begin : gen_data_connections
                // Input assignments
                assign s_axis_tdata_core[j] = s_axis_tdata[j][i*IN_WIDTH +: IN_WIDTH];
                
                // Output assignments (only if j < N_OUT)
                if (j < N_OUT) begin
                    assign m_axis_tdata[j][i*IN_WIDTH +: IN_WIDTH] = m_axis_tdata_core[j];
                end else begin
                    assign m_axis_tdata[j][i*IN_WIDTH +: IN_WIDTH] = 0;
                end
            end

            // Instantiate real-time data path
            axis_matmux_core #(
                .IN_COUNT_WIDTH(IN_COUNT_WIDTH),
                .N_OUT(N_OUT),
                .IN_WIDTH(IN_WIDTH),
                .STAGE_DELAY(STAGE_DELAY)
            ) core (
                .aclk(aclk),
                .aresetn(aresetn),
                .s_axis_tvalid(s_axis_tvalid[N_IN-1:0]),
                .s_axis_tready(s_axis_tready_core[i]),
                .s_axis_tdata(s_axis_tdata_core[N_IN-1:0]),
                .m_axis_tvalid(m_axis_tvalid_core[i]),
                .m_axis_tready(m_axis_tready[N_OUT-1:0]),
                .m_axis_tdata(m_axis_tdata_core[N_OUT-1:0]),
                .shift_matrix(shift_matrix_r4),
                .output_enables(output_enables_r4)
            );
        end
    endgenerate

    // AND reduction for tready signals
    genvar j_in;
    generate
        for (j_in = 0; j_in <= 15; j_in++) begin : gen_tready_reduction
            if (j_in < N_IN) begin
                logic ready_reduction;
                integer p;
                always_comb begin
                    ready_reduction = 1'b1;
                    for (p = 0; p < N_PARALLELISM; p++) begin
                        ready_reduction = ready_reduction & s_axis_tready_core[p][j_in];
                    end
                end
                assign s_axis_tready[j_in] = ready_reduction;
            end else begin
                assign s_axis_tready[j_in] = 1'b0;
            end
        end
    endgenerate

    // AND reduction for tvalid signals
    genvar j_out;
    generate
        for (j_out = 0; j_out <= 15; j_out++) begin : gen_tvalid_reduction
            if (j_out < N_OUT) begin
                logic valid_reduction;
                integer p;
                always_comb begin
                    valid_reduction = 1'b1;
                    for (p = 0; p < N_PARALLELISM; p++) begin
                        valid_reduction = valid_reduction & m_axis_tvalid_core[p][j_out];
                    end
                end
                assign m_axis_tvalid[j_out] = valid_reduction;
            end else begin
                assign m_axis_tvalid[j_out] = 1'b0;
            end
        end
    endgenerate

endmodule