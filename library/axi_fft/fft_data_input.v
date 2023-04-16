module fft_data_input #(
  parameter integer NFFT = 3,

  // Computed parameters
  parameter integer POINT_SIZE = $pow(2, NFFT),
  parameter integer N_ELEMENTS = POINT_SIZE * 2,
  parameter integer ELEMENTS_ADDR_SIZE = $clog2(N_ELEMENTS)
) (
  input wire clk,
  input wire resetn,

  // RAM Write Interface
  input wire [ELEMENTS_ADDR_SIZE-1:0] wAddr,
  input wire [31:0]                wData,
  input wire                       wEn,

  // M AXIS Interface
  input wire        tready,
  output reg        tvalid,
  output wire       tlast,
  output reg [63:0] tdata, // {IM, RE}

  input wire trig, // trigger data stream, single clk pulse
  output reg streaming // asserted when streaming, and ram is also locked
);
  // Definitions
  // State machine state
  localparam STATE_IDLE = 0;
  localparam STATE_STREAMING = 1;

  // State machine registers
  reg currState = 0;
  reg nextState = 0;
  reg [ELEMENTS_ADDR_SIZE-1:0] transI = 0;
  
  reg [31:0] ram [N_ELEMENTS-1:0];

  // RAM write
  always @(posedge clk) begin
    // Locks when streaming
    if (currState == STATE_IDLE && wEn == 1) begin
      ram[wAddr] = wData;
    end
  end

  assign tlast = streaming && transI == POINT_SIZE;

  // State machine next state logic
  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (trig == 1) begin
        nextState = STATE_STREAMING;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState == STATE_STREAMING) begin
      if (tlast && tready) begin
        nextState = STATE_IDLE;
      end else begin
        nextState = STATE_STREAMING;
      end
      
    end else begin
      nextState = STATE_IDLE;
    end
  end

  // State machine execute
  always @(posedge clk) begin
    case (currState)
      STATE_IDLE: begin
        // Reset
        tvalid <= 0;
        tdata <= 0;

        transI <= 0;
        streaming <= 0;
      end

      STATE_STREAMING: begin
        // begin transactions
        if (tready && tlast) begin
          tvalid <= 0;
          streaming <= 0;
        end else begin
          tvalid <= 1;
          streaming <= 1;
        end

        // Feed one by one, assert tlast on last
        // If tready is deassered during transfer, wait
        if (tready && !tlast) begin
          tdata <= {ram[(transI << 1)+1], ram[transI << 1]};
          transI <= transI + 1; // Increment index
        end
      end
      // default: unreachable
    endcase

    // Advance next state
    currState <= nextState;
  end
endmodule
