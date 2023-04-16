module fft_data_output #(
  parameter integer NFFT = 3,

  parameter integer POINT_SIZE = $pow(2, NFFT),
  parameter integer N_ELEMENTS = POINT_SIZE * 2, // RE and IM pair for each point
  parameter integer ELEMENTS_ADDR_SIZE = $clog2(N_ELEMENTS)
) (
  input wire clk,
  input wire resetn,

  // Async RAM interface
  input wire [ELEMENTS_ADDR_SIZE-1:0] rAddr,
  output wire [31:0]              rData,

  // S AXIS Interface
  output reg        tready,
  input wire        tvalid,
  input wire        tlast,
  input wire [63:0] tdata, // {IM, RE}

  output reg received // Asserted for one clk cycle when trans is done
);
  // Definitions
  // State machine states
  localparam STATE_IDLE = 0;
  localparam STATE_RECEIVING = 1;
  localparam STATE_DONE = 2;
  
  // State machine registers
  reg [1:0] currState = 0;
  reg [1:0] nextState = 0;
  reg [ELEMENTS_ADDR_SIZE-1:0] transI = 0;

  // RAM and async RAM read
  reg [31:0] ram [N_ELEMENTS-1:0];
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

    end else if (currState == STATE_RECEIVING) begin
      if (transI == POINT_SIZE || tlast) begin
        nextState = STATE_DONE;
      end else begin
        nextState = STATE_RECEIVING;
      end

    end else if (currState == STATE_DONE) begin
      nextState = STATE_IDLE;

    end else begin
      nextState = STATE_IDLE;
    end
  end

  always @(posedge clk) begin
    case (currState)
      STATE_IDLE: begin
        tready <= 0;
        transI <= 0;
        received <= 0;
      end
      STATE_RECEIVING: begin
        if (tlast) begin
          tready <= 0;
        end else begin
          tready <= 1;
        end

        if (tvalid && tready) begin
          ram[transI << 1] = tdata[31:0]; // RE
          ram[(transI << 1)+1] = tdata[63:32]; // IM
          transI <= transI + 1;
        end
      end
      STATE_DONE: begin
        received <= 1; // One clk cycle assert
      end
      // default: // Unreachable
    endcase

    // advance state
    currState <= nextState;
  end

endmodule