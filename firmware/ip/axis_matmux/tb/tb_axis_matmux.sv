`timescale 1ns / 1ps

module tb_axis_matmux;

    // Parameters
    localparam IN_COUNT_WIDTH = 2;  // 4 inputs
    localparam N_OUT = 2;           // 2 outputs
    localparam IN_WIDTH = 16;       // 16-bit inputs
    localparam STAGE_DELAY = 1;     // 1 pipeline stage
    localparam CLK_PERIOD = 10;     // 100MHz clock

    // Clock and reset
    reg aclk = 0;
    reg aresetn = 0;

    // AXI4-Lite interface signals
    reg [7:0] s_axi_awaddr;
    reg [2:0] s_axi_awprot;
    reg s_axi_awvalid;
    wire s_axi_awready;
    reg [31:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;
    reg [7:0] s_axi_araddr;
    reg [2:0] s_axi_arprot;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;

    // AXI-Stream interfaces
    reg [2**IN_COUNT_WIDTH-1:0] s_axis_tvalid;
    wire [2**IN_COUNT_WIDTH-1:0] s_axis_tready;
    reg [2**IN_COUNT_WIDTH-1:0][IN_WIDTH-1:0] s_axis_tdata;
    wire [N_OUT-1:0] m_axis_tvalid;
    reg [N_OUT-1:0] m_axis_tready;
    wire [N_OUT-1:0][IN_WIDTH-1:0] m_axis_tdata;

    // Clock generation
    always #(CLK_PERIOD/2) aclk = ~aclk;

    // DUT instantiation
    axis_matmux #(
        .IN_COUNT_WIDTH(IN_COUNT_WIDTH),
        .N_OUT(N_OUT),
        .IN_WIDTH(IN_WIDTH),
        .STAGE_DELAY(STAGE_DELAY)
    ) dut (
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
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata)
    );

    // Task to perform AXI4-Lite write
    task axi_write;
        input [7:0] addr;
        input [31:0] data;
        input [3:0] strb;
        begin
            // Address phase
            s_axi_awaddr = addr;
            s_axi_awvalid = 1;
            s_axi_wdata = data;
            s_axi_wstrb = strb;
            s_axi_wvalid = 1;
            
            wait(s_axi_awready && s_axi_wready);
            @(posedge aclk);
            
            s_axi_awvalid = 0;
            s_axi_wvalid = 0;
            
            // Response phase
            s_axi_bready = 1;
            wait(s_axi_bvalid);
            @(posedge aclk);
            
            s_axi_bready = 0;
        end
    endtask

    // Task to perform AXI4-Lite read
    task axi_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            // Address phase
            s_axi_araddr = addr;
            s_axi_arvalid = 1;
            s_axi_rready = 1;
            
            wait(s_axi_arready);
            @(posedge aclk);
            
            s_axi_arvalid = 0;
            
            // Data phase
            wait(s_axi_rvalid);
            data = s_axi_rdata;
            @(posedge aclk);
            
            s_axi_rready = 0;
        end
    endtask

    // Test stimulus
    initial begin
        // Initialize signals
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;
        s_axi_awaddr = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_araddr = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        m_axis_tready = {N_OUT{1'b1}};

        // Reset sequence
        aresetn = 0;
        repeat(5) @(posedge aclk);
        aresetn = 1;
        @(posedge aclk);

        // Test case 1: Verify outputs are disabled by default
        $display("Test case 1: Verify outputs are disabled by default");
        begin
            reg [31:0] rdata;
            
            // Read configuration
            axi_read(8'h00, rdata);
            if (rdata[31:16] !== 16'h0)
                $error("Test case 1 failed: Outputs not disabled in config register");

            // Send test data
            s_axis_tdata[0] = 16'h0010; // 16
            s_axis_tdata[1] = 16'h0020; // 32
            s_axis_tdata[2] = 16'h0040; // 64
            s_axis_tdata[3] = 16'h0080; // 128
            s_axis_tvalid = 4'b1111;
            
            repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
            
            if (|m_axis_tvalid)
                $error("Test case 1 failed: Output valid asserted when disabled");
            if (|m_axis_tdata[0] || |m_axis_tdata[1])
                $error("Test case 1 failed: Output data non-zero when disabled");
        end

        // Test case 2: Configure matrix and enable output 0
        $display("Test case 2: Configure matrix and enable output 0");
        begin
            // Configure shift matrix for output 0
            axi_write(8'h04, 32'h18141004, 4'hF); // Set shifts: 4, 2, 3, 3
            
            // Enable output 0 only
            axi_write(8'h00, 32'h0001_0000, 4'hC);
            
            repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
            
            if (m_axis_tvalid !== 2'b01)
                $error("Test case 2 failed: Expected valid=2'b01, got %b", m_axis_tvalid);
            
            // Expected: (16>>4) + (32>>2) + (64>>3) + (128>>3)
            //        = 1 + 8 + 8 + 16 = 33
            if (m_axis_tdata[0] !== 16'h0021)
                $error("Test case 2 failed: Wrong output data. Expected 33, got %d",
                    m_axis_tdata[0]);
            if (|m_axis_tdata[1])
                $error("Test case 2 failed: Output 1 should be zero");
        end

        // Test case 3: Enable/disable during operation
        $display("Test case 3: Enable/disable during operation");
        begin
            // Enable both outputs
            axi_write(8'h00, 32'h0003_0000, 4'hC);
            repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
            
            if (m_axis_tvalid !== 2'b11)
                $error("Test case 3 failed: Both outputs not enabled");
                
            // Disable all outputs
            axi_write(8'h00, 32'h0000_0000, 4'hC);
            repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
            
            if (|m_axis_tvalid)
                $error("Test case 3 failed: Outputs not disabled");
            if (|m_axis_tdata[0] || |m_axis_tdata[1])
                $error("Test case 3 failed: Output data non-zero after disable");
        end

        // End simulation
        repeat(5) @(posedge aclk);
        $display("All tests completed");
        $finish;
    end

    // Optional: Timeout watchdog
    initial begin
        #10000;
        $error("Simulation timeout");
        $finish;
    end

endmodule 