module fft_data_input #(
  parameter NFFT = 8
) (
  input wire clk,
  input wire resetn,

  // RAM Write Interface
  input wire [$clog2(NFFT*2)-1:0]  wAddr,
  input wire [31:0]                wData,
  input wire                       wEn,

  // M AXIS Interface
  input wire        tready,
  output reg        tvalid,
  output reg        tlast,
  output reg [63:0] tdata, // {IM, RE}

  input wire trig, // trigger data stream, single clk pulse
  output reg streaming // asserted when streaming, and ram is also locked
);
  // Definitions
  // State machine state
  localparam STATE_IDLE = 0;
  localparam STATE_WAIT_READY = 1;
  localparam STATE_STREAMING = 2;

  // State machine registers
  reg [1:0] currState = 0;
  reg [1:0] nextState = 0;
  reg [$clog2(NFFT)-1:0] transI = 0;
  
  reg [31:0] ram [(NFFT*2)-1:0];

  // RAM write
  always @(posedge clk) begin
    // Locks when streaming
    if (currState == STATE_IDLE && wEn == 1) begin
      ram[wAddr] = wData;
    end
  end

  // State machine next state logic
  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (trig == 1) begin
        nextState = STATE_WAIT_READY;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState == STATE_WAIT_READY) begin
      if (tready == 1) begin
        nextState = STATE_STREAMING;
      end else begin
        nextState = STATE_WAIT_READY;
      end

    end else if (currState == STATE_STREAMING) begin
      if (transI == NFFT-1) begin
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
        tlast <= 0;
        tdata <= 0;

        transI <= 0;
      end 

      STATE_WAIT_READY: begin
        tvalid <= 1;
        tdata <= {ram[1], ram[0]}; // preload first transactions
        
        streaming <= 1;
      end

      STATE_STREAMING: begin
        // Feed one by one, assert tlast on last
        tdata <= {ram[(transI << 1)-1], ram[transI << 1]};
        transI <= transI + 1;

        if (transI == NFFT-1) begin
          tlast <= 1;
        end
      end
      // default: unreachable
    endcase

    // Advance next state
    currState <= nextState;
  end
endmodule
