module fft_data_output #(
  parameter NFFT = 8
) (
  input wire clk,
  input wire resetn,

  // Async RAM interface
  input wire [$clog2(NFFT*2)-1:0] rAddr,
  output wire [31:0]              rData,

  // S AXIS Interface
  output reg        tready,
  input wire        tvalid,
  input wire        tlast,
  input wire [63:0] tdata, // {IM, RE}

  output reg receiving // Asserted when a transaction is ongoing
);
  // Definitions
  // State machine states
  localparam STATE_IDLE = 0;
  localparam STATE_RECEIVING = 1;
  
  // State machine registers
  reg currState = 0;
  reg nextState = 0;
  reg [$clog2(NFFT)-1:0] transI = 0;

  // RAM and async RAM read
  reg [31:0] ram [(NFFT*2)-1:0];
  assign rData = ram[rAddr];

  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (tvalid == 1) begin
        nextState = STATE_RECEIVING;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState ==  STATE_RECEIVING) begin
      if (transI == NFFT-1) begin
        nextState = STATE_IDLE;
      end else begin
        nextState = STATE_RECEIVING;
      end

    end else begin
      nextState = STATE_IDLE;
    end
  end

  always @(posedge clk) begin
    case (currState)
      STATE_IDLE: begin
        tready <= 0;
        transI <= 0;
        receiving <= 0;
      end
      STATE_RECEIVING: begin
        receiving <= 1;
        tready <= 1;

        ram[transI << 1] = tdata[31:0]; // RE
        ram[(transI << 1)+1] = tdata[63:32]; // IM
        transI <= transI + 1;
      end
      // default: // Unreachable
    endcase
  end

endmodule