module axis_matmux_core
    #(
        parameter IN_COUNT_WIDTH = 2,  // Number of input bits (1-4), actual inputs = 2^IN_COUNT_WIDTH
        parameter N_OUT = 1,           // Number of outputs (1-16)
        parameter IN_WIDTH = 16,       // Width of each input in bits
        parameter STAGE_DELAY = 1      // Number of pipeline stages between each adder level
    )
    (
        // Clock and reset
        input  wire                  aclk,
        input  wire                  aresetn,

        // AXIS Slave interfaces for input data
        input  wire [2**IN_COUNT_WIDTH-1:0]           s_axis_tvalid,
        output wire [2**IN_COUNT_WIDTH-1:0]           s_axis_tready,
        input  wire [2**IN_COUNT_WIDTH-1:0][IN_WIDTH-1:0] s_axis_tdata,

        // AXIS Master interfaces for output data
        output wire [N_OUT-1:0]                 m_axis_tvalid,
        input  wire [N_OUT-1:0]                 m_axis_tready,
        output wire [N_OUT-1:0][IN_WIDTH-1:0]   m_axis_tdata,

        // Matrix configuration input
        input wire [4:0]            shift_matrix [0:N_OUT-1][0:2**IN_COUNT_WIDTH-1],
        input wire [N_OUT-1:0]           output_enables
    );

    // Local parameters
    localparam N_IN = 2**IN_COUNT_WIDTH;

    // Matrix multiplication and adder tree logic
    genvar out_idx;
    generate
        for (out_idx = 0; out_idx < N_OUT; out_idx++) begin : gen_outputs
            // Pipeline registers for each stage
            reg [N_IN-1:0][IN_WIDTH-1:0] stage_data [0:IN_COUNT_WIDTH*STAGE_DELAY];
            reg [N_IN-1:0] stage_valid [0:IN_COUNT_WIDTH*STAGE_DELAY];
            
            // Reset
            // always @(posedge aclk) begin
            //     if (!aresetn) begin
            //         for (int stage = 0; stage <= IN_COUNT_WIDTH*STAGE_DELAY; stage++) begin
            //             for (int i = 0; i < N_IN; i++) begin
            //                 stage_data[stage][i] <= '0;
            //                 stage_valid[stage][i] <= '0;
            //             end
            //         end
            //     end
            // end
            
            // First stage: Apply shifts
            always @(posedge aclk) begin
                for (int i = 0; i < N_IN; i++) begin
                    if (aresetn) begin
                        stage_data[0][i] <= (s_axis_tdata[i] >> shift_matrix[out_idx][i]);
                        stage_valid[0][i] <= s_axis_tvalid[i] && output_enables[out_idx];
                    end else begin
                        stage_data[0][i] <= '0;
                        stage_valid[0][i] <= '0;
                    end
                end
            end

            // Generate adder tree stages
            for (genvar stage = 0; stage < IN_COUNT_WIDTH; stage++) begin : gen_stages
                localparam int PAIRS = 2**(IN_COUNT_WIDTH-stage-1);
                
                // Intermediate signals for adder outputs
                (* keep = "true" *)logic [PAIRS-1:0][IN_WIDTH-1:0] adder_data;
                (* keep = "true" *)logic [PAIRS-1:0] adder_valid;
                
                // Compute adder outputs combinatorially
                always_comb begin
                    if (aresetn) begin
                        for (int i = 0; i < PAIRS; i++) begin
                            if (stage_valid[stage*STAGE_DELAY][i*2] && stage_valid[stage*STAGE_DELAY][i*2+1]) begin
                                adder_data[i] = stage_data[stage*STAGE_DELAY][i*2] + stage_data[stage*STAGE_DELAY][i*2+1];
                                adder_valid[i] = 1'b1;
                            end else if (stage_valid[stage*STAGE_DELAY][i*2]) begin
                                adder_data[i] = stage_data[stage*STAGE_DELAY][i*2];
                                adder_valid[i] = 1'b1;
                            end else if (stage_valid[stage*STAGE_DELAY][i*2+1]) begin
                                adder_data[i] = stage_data[stage*STAGE_DELAY][i*2+1];
                                adder_valid[i] = 1'b1;
                            end else begin
                                adder_data[i] = '0;
                                adder_valid[i] = 1'b0;
                            end
                        end
                    end else begin
                        for (int i = 0; i < PAIRS; i++) begin
                            adder_data[i] = '0;
                            adder_valid[i] = 1'b0;
                        end
                    end
                end
                
                // Pipeline stages for each adder output
                for (genvar delay = 0; delay < STAGE_DELAY; delay++) begin : gen_delays
                    localparam int CURR_STAGE = stage*STAGE_DELAY + delay;
                    localparam int NEXT_STAGE = CURR_STAGE + 1;
                    
                    always @(posedge aclk) begin
                        if (aresetn) begin
                            if (delay == 0) begin
                                // First pipeline stage takes from adder outputs
                                for (int i = 0; i < PAIRS; i++) begin
                                    stage_data[NEXT_STAGE][i] <= adder_data[i];
                                    stage_valid[NEXT_STAGE][i] <= adder_valid[i];
                                end
                            end else begin
                                // Subsequent pipeline stages pass data through
                                for (int i = 0; i < PAIRS; i++) begin
                                    stage_data[NEXT_STAGE][i] <= stage_data[CURR_STAGE][i];
                                    stage_valid[NEXT_STAGE][i] <= stage_valid[CURR_STAGE][i];
                                end
                            end
                        end else begin
                            for (int i = 0; i < N_IN; i++) begin
                                stage_data[NEXT_STAGE][i] <= '0;
                                stage_valid[NEXT_STAGE][i] <= '0;
                            end
                        end
                    end
                end
            end

            // Assign outputs with backpressure
            assign m_axis_tvalid[out_idx] = m_axis_tready[out_idx] && stage_valid[IN_COUNT_WIDTH*STAGE_DELAY][0];
            assign m_axis_tdata[out_idx] = (m_axis_tready[out_idx] && stage_valid[IN_COUNT_WIDTH*STAGE_DELAY][0]) ? stage_data[IN_COUNT_WIDTH*STAGE_DELAY][0] : '0;
            
        end
    endgenerate

    // Ready signals for all inputs
    assign s_axis_tready = {N_IN{&m_axis_tready}};

endmodule 