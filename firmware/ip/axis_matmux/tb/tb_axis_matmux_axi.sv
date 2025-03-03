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
    reg [8:0] s_axi_awaddr;
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
    reg [8:0] s_axi_araddr;
    reg [2:0] s_axi_arprot;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;

    // Matrix configuration output
    wire [4:0] shift_matrix [0:N_OUT-1][0:2**IN_COUNT_WIDTH-1];
    wire [N_OUT-1:0] output_enables;

    reg [15:0] test_case;

    // Clock generation
    always #(CLK_PERIOD/2) aclk = ~aclk;

    // DUT instantiation
    axis_matmux_axi #(
        .IN_COUNT_WIDTH(IN_COUNT_WIDTH),
        .N_OUT(N_OUT)
    ) dut (
        .axi_aclk(aclk),
        .axi_aresetn(aresetn),
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
        input [8:0] addr;
        input [31:0] data;
        input [3:0] strb;
        begin
            // Address phase
            s_axi_awaddr = addr;
            s_axi_awvalid = 1;
            s_axi_wdata = data;
            s_axi_wstrb = strb;
            s_axi_wvalid = 1;
            s_axi_bready = 1;  // Assert bready from the start
            
            wait(s_axi_awready && s_axi_wready);
            @(posedge aclk);
            
            s_axi_awvalid = 0;
            s_axi_wvalid = 0;
            
            // Response phase
            wait(s_axi_bvalid);
            @(posedge aclk);
            
            s_axi_bready = 0;
        end
    endtask

    // Task to perform AXI4-Lite read
    task axi_read;
        input [8:0] addr;
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
        test_case = 0;
        aresetn = 0;
        repeat(5) @(posedge aclk);
        aresetn = 1;
        @(posedge aclk);

        // Test case 1: Verify default state
        $display("Test case 1: Verify default state");
        test_case = 1;
        begin
            reg [31:0] rdata;
            axi_read(9'h100, rdata);
            if (rdata !== {16'h0, N_OUT[7:0], 4'h0, IN_COUNT_WIDTH[3:0]})
                $error("Test case 1 failed: Wrong default config value");
            if (output_enables !== 16'h0)
                $error("Test case 1 failed: Outputs not disabled by default");
        end

        // Test case 2: Configure matrix for output 0
        $display("Test case 2: Configure matrix for output 0");
        test_case = 2;
        begin
            reg [31:0] rdata;
            // Write shifts for inputs 0-3
            axi_write(9'h000, 32'h04030201, 4'hF);
            // Write shifts for inputs 4-7
            axi_write(9'h004, 32'h08070605, 4'hF);
            // Read back and verify
            axi_read(9'h000, rdata);
            if (rdata !== 32'h04030201)
                $error("Test case 2 failed: Wrong matrix values for inputs 0-3");
        end

        // Test case 3: Enable outputs
        $display("Test case 3: Enable outputs");
        test_case = 3;
        begin
            reg [31:0] rdata;
            // Enable output 0
            axi_write(9'h100, 32'h0001_0000, 4'hC);
            axi_read(9'h100, rdata);
            if (rdata[31:16] !== 16'h0001)
                $error("Test case 3 failed: Output 0 not enabled");
            if (output_enables !== 16'h0001)
                $error("Test case 3 failed: Output enable signal mismatch");

            // Enable both outputs
            axi_write(9'h100, 32'h0003_0000, 4'hC);
            axi_read(9'h100, rdata);
            if (rdata[31:16] !== 16'h0003)
                $error("Test case 3 failed: Both outputs not enabled");
            if (output_enables !== 16'h0003)
                $error("Test case 3 failed: Output enable signal mismatch");
        end

        // Test case 4: Invalid output enables
        $display("Test case 4: Invalid output enables");
        test_case = 4;
        begin
            reg [31:0] rdata;
            // Try to enable non-existent outputs
            axi_write(9'h100, 32'hFFFF_0000, 4'hC);
            axi_read(9'h100, rdata);
            if (rdata[31:16] !== 16'h0003)  // Only outputs 0,1 should be enabled
                $error("Test case 4 failed: Invalid outputs were enabled");
        end

        // Test case 5: Write protection
        $display("Test case 5: Write protection");
        test_case = 5;
        begin
            reg [31:0] rdata;
            // Try to modify read-only fields
            axi_write(9'h100, 32'h0000_FFFF, 4'h3);
            axi_read(9'h100, rdata);
            if (rdata[15:0] !== {N_OUT[7:0], 4'h0, IN_COUNT_WIDTH[3:0]})
                $error("Test case 5 failed: Read-only fields were modified");
        end

        // Test case 6: Reproduce hardware issue
        $display("Test case 6: Reproduce hardware issue");
        test_case = 6;
        begin
            reg [31:0] rdata;
            
            // Reset the DUT
            aresetn = 0;
            repeat(5) @(posedge aclk);
            aresetn = 1;
            @(posedge aclk);
            
            // First read configuration register
            axi_read(9'h100, rdata);
            $display("Read 0x100: %h", rdata);
            
            // Read initial matrix values
            axi_read(9'h000, rdata);
            $display("Read 0x0: %h", rdata);
            axi_read(9'h004, rdata);
            $display("Read 0x4: %h", rdata);
            axi_read(9'h010, rdata);
            $display("Read 0x10: %h", rdata);
            axi_read(9'h014, rdata);
            $display("Read 0x14: %h", rdata);
            
            // Write to configuration register
            axi_write(9'h100, 32'h0001_0000, 4'hF);
            $display("Wrote 0x100: %h", 32'h0001_0000);
            
            // Read back all values again
            axi_read(9'h100, rdata);
            $display("Read 0x100: %h", rdata);
            axi_read(9'h000, rdata);
            $display("Read 0x0: %h", rdata);
            axi_read(9'h004, rdata);
            $display("Read 0x4: %h", rdata);
            axi_read(9'h010, rdata);
            $display("Read 0x10: %h", rdata);
            axi_read(9'h014, rdata);
            $display("Read 0x14: %h", rdata);
            
            // Check if matrix values were incorrectly modified
            if (shift_matrix[0][0] !== 0 || shift_matrix[0][1] !== 0)
                $error("Test case 6 failed: Matrix values were modified by config write");
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