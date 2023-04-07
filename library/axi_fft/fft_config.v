module fft_config (
  input wire clk,
  input wire resetn,

  input wire [7:0] scaleSch,
  input wire forward,

  input wire       tready,
  output reg       tvalid,
  output reg       tlast,
  output reg [8:0] tdata,

  input wire commit
);
  // Definitions
  localparam STATE_IDLE = 0;
  localparam STATE_WAIT_READY = 1;

  // State machine registers
  reg currState = 0;
  reg nextState = 0;

  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (commit == 1) begin
        nextState = STATE_WAIT_READY;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState == STATE_WAIT_READY) begin
      if (tready == 1) begin
        nextState = STATE_IDLE;
      end else begin
        nextState = STATE_WAIT_READY;
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

      STATE_WAIT_READY: begin
        // Load data
        tvalid <= 1;
        tlast <= 1;
        tdata <= {scaleSch, forward};
      end
      // default: Unreachable
    endcase
  end
endmodule
