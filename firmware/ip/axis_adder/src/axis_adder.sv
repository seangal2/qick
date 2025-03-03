module axis_adder
    #(
        parameter N_IN = 2,        // Number of input streams (2 to 4)
        parameter N_DDS = 8        // Number of DDS blocks
    )
    (
        // Clock and reset
        input  wire                  aclk,
        input  wire                  aresetn,

        // AXIS Slave interfaces for input data
        input  wire                  s0_axis_tvalid,
        output wire                  s0_axis_tready,
        input  wire [N_DDS*16-1:0]   s0_axis_tdata,

        input  wire                  s1_axis_tvalid,
        output wire                  s1_axis_tready,
        input  wire [N_DDS*16-1:0]   s1_axis_tdata,

        input  wire                  s2_axis_tvalid,
        output wire                  s2_axis_tready,
        input  wire [N_DDS*16-1:0]   s2_axis_tdata,

        input  wire                  s3_axis_tvalid,
        output wire                  s3_axis_tready,
        input  wire [N_DDS*16-1:0]   s3_axis_tdata,

        // AXIS Master interface for output data
        output wire                  m_axis_tvalid,
        input  wire                  m_axis_tready,
        output wire [N_DDS*16-1:0]   m_axis_tdata
    );

    // Internal signals
    reg [N_DDS*16-1:0] sum_data;
    reg valid_reg;
    reg valid_r1;
    // reg valid_r2;

    // Sum tree
    reg [N_DDS*16-1:0] sum_01;
    reg [N_DDS*16-1:0] sum_23;

    // Ready signals for all inputs
    assign s0_axis_tready = m_axis_tready;
    assign s1_axis_tready = m_axis_tready;
    assign s2_axis_tready = (N_IN > 2) ? m_axis_tready : 1'b0;
    assign s3_axis_tready = (N_IN > 3) ? m_axis_tready : 1'b0;

    // Sum the input data
    always @(posedge aclk) begin
        if (!aresetn) begin
            sum_data <= 0;
            sum_01 <= 0;
            sum_23 <= 0;
            valid_reg <= 0;
            valid_r1 <= 0;
//            valid_r2 <= 0;
        end else begin
            if (m_axis_tready) begin
                valid_reg <= 1;
                valid_r1 <= valid_reg;
                // valid_r2 <= valid_r1;
                for (int j = 0; j < N_DDS; j++) begin
                    if (s0_axis_tvalid && s1_axis_tvalid) begin
                        sum_01[j*16 +: 16] <= s0_axis_tdata[j*16 +: 16] + s1_axis_tdata[j*16 +: 16];
                    end else if (s0_axis_tvalid) begin
                        sum_01[j*16 +: 16] <= s0_axis_tdata[j*16 +: 16];
                    end else if (s1_axis_tvalid) begin
                        sum_01[j*16 +: 16] <= s1_axis_tdata[j*16 +: 16];
                    end else begin
                        sum_01[j*16 +: 16] <= 0;
                    end

                    if (N_IN > 2 && s2_axis_tvalid && s3_axis_tvalid) begin
                        sum_23[j*16 +: 16] <= s2_axis_tdata[j*16 +: 16] + s3_axis_tdata[j*16 +: 16];
                    end else if (s2_axis_tvalid) begin
                        sum_23[j*16 +: 16] <= s2_axis_tdata[j*16 +: 16];
                    end else if (s3_axis_tvalid) begin
                        sum_23[j*16 +: 16] <= s3_axis_tdata[j*16 +: 16];
                    end else begin
                        sum_23[j*16 +: 16] <= 0;
                    end
                    
                    sum_data[j*16 +: 16] <= sum_01[j*16 +: 16] + sum_23[j*16 +: 16];
                end
            end
        end
    end

    // Output assignment
    assign m_axis_tdata = sum_data;
    assign m_axis_tvalid = valid_r1;

endmodule