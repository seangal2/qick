module tb();

    // Parameters
    localparam N_IN = 2;        // Number of input streams to test
    localparam N_DDS = 16;       // Number of DDS blocks
    
    // Clock and reset
    reg                     aclk = 0;
    reg                     aresetn = 0;
    
    // Input interfaces
    reg                     s0_axis_tvalid = 0;
    wire                    s0_axis_tready;
    reg [N_DDS*16-1:0]     s0_axis_tdata = 0;
    
    reg                     s1_axis_tvalid = 0;
    wire                    s1_axis_tready;
    reg [N_DDS*16-1:0]     s1_axis_tdata = 0;
    
    reg                     s2_axis_tvalid = 0;
    wire                    s2_axis_tready;
    reg [N_DDS*16-1:0]     s2_axis_tdata = 0;
    
    reg                     s3_axis_tvalid = 0;
    wire                    s3_axis_tready;
    reg [N_DDS*16-1:0]     s3_axis_tdata = 0;
    
    // Output interface
    wire                    m_axis_tvalid;
    reg                     m_axis_tready = 0;
    wire [N_DDS*16-1:0]    m_axis_tdata;

    // Instantiate DUT
    axis_adder #(
        .N_IN(N_IN),
        .N_DDS(N_DDS)
    ) DUT (
        .aclk           (aclk),
        .aresetn        (aresetn),
        
        .s0_axis_tvalid (s0_axis_tvalid),
        .s0_axis_tready (s0_axis_tready),
        .s0_axis_tdata  (s0_axis_tdata),
        
        .s1_axis_tvalid (s1_axis_tvalid),
        .s1_axis_tready (s1_axis_tready),
        .s1_axis_tdata  (s1_axis_tdata),
        
        .s2_axis_tvalid (s2_axis_tvalid),
        .s2_axis_tready (s2_axis_tready),
        .s2_axis_tdata  (s2_axis_tdata),
        
        .s3_axis_tvalid (s3_axis_tvalid),
        .s3_axis_tready (s3_axis_tready),
        .s3_axis_tdata  (s3_axis_tdata),
        
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tdata   (m_axis_tdata)
    );

    // Clock generation
    always #5 aclk = ~aclk;

    // Test stimulus
    initial begin
        // Initialize
        @(posedge aclk);
        aresetn <= 0;
        
        // Wait 5 clock cycles and release reset
        repeat(5) @(posedge aclk);
        aresetn <= 1;
        
        // Test case 1: Single input active
        @(posedge aclk);
        m_axis_tready <= 1;
        s0_axis_tvalid <= 1;
        s0_axis_tdata <= {16'h1111, 16'h2222, 16'h3333, 16'h4444, 
                         16'h5555, 16'h6666, 16'h7777, 16'h8888};
        
        @(posedge aclk);
        s0_axis_tdata <= {16'h2222, 16'h3333, 16'h4444, 16'h5555, 
                         16'h6666, 16'h7777, 16'h8888, 16'h9999};
        @(posedge aclk);
        s0_axis_tvalid <= 0;
        
        // Test case 2: Two inputs active
        repeat(2) @(posedge aclk);
        s0_axis_tvalid <= 1;
        s1_axis_tvalid <= 1;
        s0_axis_tdata <= {16'h1111, 16'h2222, 16'h3333, 16'h4444,
                         16'h5555, 16'h6666, 16'h7777, 16'h8888};
        s1_axis_tdata <= {16'h2222, 16'h3333, 16'h4444, 16'h5555,
                         16'h6666, 16'h7777, 16'h8888, 16'h9999};
        
        @(posedge aclk);
        s0_axis_tvalid <= 0;
        s1_axis_tvalid <= 0;
        
        // Test case 3: Three inputs active (if N_IN > 2)
        if (N_IN > 2) begin
            repeat(2) @(posedge aclk);
            s0_axis_tvalid <= 1;
            s1_axis_tvalid <= 1;
            s2_axis_tvalid <= 1;
            s0_axis_tdata <= {16'h1111, 16'h2222, 16'h3333, 16'h4444,
                             16'h5555, 16'h6666, 16'h7777, 16'h8888};
            s1_axis_tdata <= {16'h2222, 16'h3333, 16'h4444, 16'h5555,
                             16'h6666, 16'h7777, 16'h8888, 16'h9999};
            s2_axis_tdata <= {16'h3333, 16'h4444, 16'h5555, 16'h6666,
                             16'h7777, 16'h8888, 16'h9999, 16'hAAAA};
            
            @(posedge aclk);
            s0_axis_tvalid <= 0;
            s1_axis_tvalid <= 0;
            s2_axis_tvalid <= 0;
        end
        
        // Test case 4: Test backpressure
        repeat(2) @(posedge aclk);
        m_axis_tready <= 0;
        s0_axis_tvalid <= 1;
        s1_axis_tvalid <= 1;
        
        repeat(2) @(posedge aclk);
        m_axis_tready <= 1;
        
        @(posedge aclk);
        s0_axis_tvalid <= 0;
        s1_axis_tvalid <= 0;
        
        // End simulation
        repeat(5) @(posedge aclk);
        $finish;
    end

endmodule