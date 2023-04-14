module fft_config (
  input wire clk,
  input wire resetn,

  input wire [7:0] scaleSch,
  input wire forward,

  input wire        tready,
  output reg        tvalid,
  output reg        tlast,
  output reg [15:0] tdata,

  input wire commit
);
  // Definitions
  localparam STATE_IDLE = 0;
  localparam STATE_TRANSMIT = 1;

  // State machine registers
  reg currState = 0;
  reg nextState = 0;

  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (commit == 1) begin
        nextState = STATE_TRANSMIT;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState == STATE_TRANSMIT) begin
      if (tready == 1) begin
        nextState = STATE_IDLE;
      end else begin
        nextState = STATE_TRANSMIT;
      end

    end else begin
      nextState = STATE_IDLE;
    end
  end

  always @(posedge clk) begin
    case (currState)
      STATE_IDLE: begin
        tvalid <= 0;
        tlast <= 0;
        tdata <= 0;
      end

      STATE_TRANSMIT: begin
        // Load data
        tvalid <= 1;
        tlast <= 1;
        tdata <= {7'b0, scaleSch, forward};
      end
      // default: Unreachable
    endcase

    // advance state
    currState <= nextState;
  end
endmodule
