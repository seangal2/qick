`timescale 1ns / 1ps

module tb_axis_matmux_axi;

    // Parameters
    localparam IN_COUNT_WIDTH = 2;  // 4 inputs
    localparam N_OUT = 2;           // 2 outputs
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

    // Matrix configuration output
    wire [4:0] shift_matrix [0:15][0:15];
    wire [15:0] output_enables;

    // Clock generation
    always #(CLK_PERIOD/2) aclk = ~aclk;

    // DUT instantiation
    axis_matmux_axi #(
        .IN_COUNT_WIDTH(IN_COUNT_WIDTH),
        .N_OUT(N_OUT)
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
        .shift_matrix(shift_matrix),
        .output_enables(output_enables)
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

        // Reset sequence
        aresetn = 0;
        repeat(5) @(posedge aclk);
        aresetn = 1;
        @(posedge aclk);

        // Test case 1: Verify default state
        $display("Test case 1: Verify default state");
        begin
            reg [31:0] rdata;
            axi_read(8'h00, rdata);
            if (rdata !== {16'h0, N_OUT[7:0], 4'h0, IN_COUNT_WIDTH[3:0]})
                $error("Test case 1 failed: Wrong default config value");
            if (output_enables !== 16'h0)
                $error("Test case 1 failed: Outputs not disabled by default");
        end

        // Test case 2: Enable outputs
        $display("Test case 2: Enable outputs");
        begin
            reg [31:0] rdata;
            // Enable output 0
            axi_write(8'h00, 32'h0001_0000, 4'hC);
            axi_read(8'h00, rdata);
            if (rdata[31:16] !== 16'h0001)
                $error("Test case 2 failed: Output 0 not enabled");
            if (output_enables !== 16'h0001)
                $error("Test case 2 failed: Output enable signal mismatch");

            // Enable both outputs
            axi_write(8'h00, 32'h0003_0000, 4'hC);
            axi_read(8'h00, rdata);
            if (rdata[31:16] !== 16'h0003)
                $error("Test case 2 failed: Both outputs not enabled");
            if (output_enables !== 16'h0003)
                $error("Test case 2 failed: Output enable signal mismatch");
        end

        // Test case 3: Invalid output enables
        $display("Test case 3: Invalid output enables");
        begin
            reg [31:0] rdata;
            // Try to enable non-existent outputs
            axi_write(8'h00, 32'hFFFF_0000, 4'hC);
            axi_read(8'h00, rdata);
            if (rdata[31:16] !== 16'h0003)  // Only outputs 0,1 should be enabled
                $error("Test case 3 failed: Invalid outputs were enabled");
        end

        // Test case 4: Write protection
        $display("Test case 4: Write protection");
        begin
            reg [31:0] rdata;
            // Try to modify read-only fields
            axi_write(8'h00, 32'h0000_FFFF, 4'h3);
            axi_read(8'h00, rdata);
            if (rdata[15:0] !== {N_OUT[7:0], 4'h0, IN_COUNT_WIDTH[3:0]})
                $error("Test case 4 failed: Read-only fields were modified");
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