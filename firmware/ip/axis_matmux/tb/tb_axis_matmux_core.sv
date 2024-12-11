`timescale 1ns / 1ps

module tb_axis_matmux_core;

    // Parameters
    localparam IN_COUNT_WIDTH = 2;  // 4 inputs
    localparam N_OUT = 2;           // 2 outputs
    localparam IN_WIDTH = 16;       // 16-bit inputs
    localparam N_PARALLELISM = 1;  // Add parallelism parameter
    localparam STAGE_DELAY = 1;     // 1 pipeline stage
    localparam CLK_PERIOD = 10;     // 100MHz clock

    // Clock and reset
    reg aclk = 0;
    reg aresetn = 0;

    // Input AXI-Stream interfaces
    reg [2**IN_COUNT_WIDTH-1:0] s_axis_tvalid;
    wire [2**IN_COUNT_WIDTH-1:0] s_axis_tready;
    reg [2**IN_COUNT_WIDTH-1:0][N_PARALLELISM*IN_WIDTH-1:0] s_axis_tdata;

    // Output AXI-Stream interfaces
    wire [N_OUT-1:0] m_axis_tvalid;
    reg [N_OUT-1:0] m_axis_tready;
    wire [N_OUT-1:0][N_PARALLELISM*IN_WIDTH-1:0] m_axis_tdata;

    // Configuration matrix
    reg [4:0] shift_matrix [0:N_OUT-1][0:2**IN_COUNT_WIDTH-1];
    reg [N_OUT-1:0] output_enables;

    reg [15:0] test_case;

    // Clock generation
    always #(CLK_PERIOD/2) aclk = ~aclk;

    // DUT instantiation
    axis_matmux_core #(
        .IN_COUNT_WIDTH(IN_COUNT_WIDTH),
        .N_OUT(N_OUT),
        .IN_WIDTH(IN_WIDTH),
        .N_PARALLELISM(N_PARALLELISM),  // Add parallelism parameter
        .STAGE_DELAY(STAGE_DELAY)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .shift_matrix(shift_matrix),
        .output_enables(output_enables)
    );

    // Test stimulus
    initial begin
        // Initialize signals
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        m_axis_tready = 2'b11;
        output_enables = 0;  // All outputs disabled by default
        
        // Initialize shift matrix
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                shift_matrix[i][j] = 0;
            end
        end

        // Reset sequence
        test_case = 0;
        aresetn = 0;
        repeat(5) @(posedge aclk);
        aresetn = 1;
        @(posedge aclk);

        // Test case 1: Verify outputs are disabled by default
        $display("Test case 1: Verify outputs are disabled by default");
        test_case = 1;
        s_axis_tdata[0] = 0;
        s_axis_tdata[0] = 16'h0001;
        s_axis_tdata[1] = 16'h0002;
        s_axis_tdata[2] = 16'h0004;
        s_axis_tdata[3] = 16'h0008;
        s_axis_tvalid = 4'b1111;
        
        repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
        
        if (|m_axis_tvalid)
            $error("Test case 1 failed: Output valid asserted when all outputs disabled");
        if (|m_axis_tdata[0] || |m_axis_tdata[1])
            $error("Test case 1 failed: Output data non-zero when outputs disabled");

        // Test case 2: Medium value inputs with no shifts
        $display("Test case 2: Medium value inputs with no shifts");
        test_case = 2;
        output_enables = 16'h0003;  // Enable both outputs
        s_axis_tdata[0] = 16'h1000;  // 4096
        s_axis_tdata[1] = 16'h0100;  // 256
        s_axis_tdata[2] = 16'h0010;  // 16
        s_axis_tdata[3] = 16'h0001;  // 1
        s_axis_tvalid = 4'b1111;
        
        repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
        
        // Expected: 4096 + 256 + 16 + 1 = 4369 (0x1111)
        if (m_axis_tdata[0] !== 16'h1111)
            $error("Test case 2 failed: Wrong sum for medium values, got %h", m_axis_tdata[0]);

        // Test case 3: Large shifts on medium values
        $display("Test case 3: Large shifts on medium values");
        test_case = 3;
        shift_matrix[0][0] = 5'h0C;  // Shift by 12 (4096 -> 1)
        shift_matrix[0][1] = 5'h08;  // Shift by 8  (256 -> 1)
        shift_matrix[0][2] = 5'h04;  // Shift by 4  (16 -> 1)
        shift_matrix[0][3] = 5'h00;  // No shift    (1 -> 1)
        
        repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
        
        // Expected: 1 + 1 + 1 + 1 = 4
        if (m_axis_tdata[0] !== 16'h0004)
            $error("Test case 3 failed: Wrong result after large shifts, got %h", m_axis_tdata[0]);

        // Test case 4: Alternating shifts
        $display("Test case 4: Alternating shifts");
        test_case = 4;
        shift_matrix[1][0] = 5'h00;  // No shift
        shift_matrix[1][1] = 5'h04;  // Shift by 4
        shift_matrix[1][2] = 5'h00;  // No shift
        shift_matrix[1][3] = 5'h04;  // Shift by 4
        s_axis_tdata[0] = 16'h0100;  // 256 -> 256
        s_axis_tdata[1] = 16'h0100;  // 256 -> 16
        s_axis_tdata[2] = 16'h0100;  // 256 -> 256
        s_axis_tdata[3] = 16'h0100;  // 256 -> 16
        
        repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
        
        // Expected: 256 + 16 + 256 + 16 = 544 (0x0220)
        if (m_axis_tdata[1] !== 16'h0220)
            $error("Test case 4 failed: Wrong alternating shift result, got %h", m_axis_tdata[1]);

        // Test case 5: Progressive values with fixed shift
        $display("Test case 5: Progressive values with fixed shift");
        test_case = 5;
        shift_matrix[0][0] = 5'h04;  // Shift by 4
        shift_matrix[0][1] = 5'h04;
        shift_matrix[0][2] = 5'h04;
        shift_matrix[0][3] = 5'h04;
        s_axis_tdata[0] = 16'h0100;  // 256 -> 16
        s_axis_tdata[1] = 16'h0200;  // 512 -> 32
        s_axis_tdata[2] = 16'h0400;  // 1024 -> 64
        s_axis_tdata[3] = 16'h0800;  // 2048 -> 128
        
        repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
        
        // Expected: 16 + 32 + 64 + 128 = 240 (0x00F0)
        if (m_axis_tdata[0] !== 16'h00F0)
            $error("Test case 5 failed: Wrong progressive value result, got %h", m_axis_tdata[0]);

        // Test case 6: Progressive shifts on fixed value
        $display("Test case 6: Progressive shifts on fixed value");
        test_case = 6;
        shift_matrix[1][0] = 5'h00;  // No shift
        shift_matrix[1][1] = 5'h01;  // Shift by 1
        shift_matrix[1][2] = 5'h02;  // Shift by 2
        shift_matrix[1][3] = 5'h03;  // Shift by 3
        s_axis_tdata[0] = 16'h0080;  // 128 -> 128
        s_axis_tdata[1] = 16'h0080;  // 128 -> 64
        s_axis_tdata[2] = 16'h0080;  // 128 -> 32
        s_axis_tdata[3] = 16'h0080;  // 128 -> 16
        
        repeat(IN_COUNT_WIDTH*STAGE_DELAY + 2) @(posedge aclk);
        
        // Expected: 128 + 64 + 32 + 16 = 240 (0x00F0)
        if (m_axis_tdata[1] !== 16'h00F0)
            $error("Test case 6 failed: Wrong progressive shift result, got %h", m_axis_tdata[1]);

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