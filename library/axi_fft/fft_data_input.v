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
  input wire [31:0]                   wData,
  input wire                          wEn,

  // M AXIS Interface
  input  wire       tready,
  output reg        tvalid,
  output wire       tlast,
  output reg [63:0] tdata, // {IM, RE}

  input wire trig, // trigger data stream, single clk pulse
  output reg streaming // asserted when streaming, and ram is also locked
);
  // Definitions
  // State machine state
  localparam STATE_IDLE      = 0;
  localparam STATE_STALL     = 1;
  localparam STATE_STREAMING = 2;

  // State machine registers
  reg [1:0]                    currState = 0;
  reg [1:0]                    nextState = 0;
  reg [ELEMENTS_ADDR_SIZE-1:0] transI    = 0;

  // Split into 2 rams to read two samples at the same time
  wire writeLocked = !wEn || streaming;

  reg  [ELEMENTS_ADDR_SIZE-1:0] rAddr;
  wire [31:0]                   rDataRe;
  wire [31:0]                   rDataIm;
  ad_mem #(
    .DATA_WIDTH(32),
    .ADDRESS_WIDTH(ELEMENTS_ADDR_SIZE-1)
  ) iRamRe (
    .clka(clk),
    .wea(!writeLocked && wAddr[0] == 1'b0),
    .addra(wAddr >> 1),
    .dina(wData),
    .clkb(clk),
    .reb(resetn), // Disable read on reset
    .addrb(rAddr),
    .doutb(rDataRe)
  );
  ad_mem #(
    .DATA_WIDTH(32),
    .ADDRESS_WIDTH(ELEMENTS_ADDR_SIZE-1)
  ) iRamIm (
    .clka(clk),
    .wea(!writeLocked && wAddr[0] == 1'b1),
    .addra(wAddr >> 1),
    .dina(wData),
    .clkb(clk),
    .reb(resetn), // Disable read on reset
    .addrb(rAddr),
    .doutb(rDataIm)
  );

  assign tlast = streaming && transI == POINT_SIZE-1;

  // State machine next state logic
  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (trig == 1) begin
        nextState = STATE_STALL;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState == STATE_STALL) begin
      // Need to stall for 2 clock cycles
      if (rAddr == 1) begin
        nextState = STATE_STREAMING;
      end else begin
        nextState = STATE_STALL;
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
        rAddr <= 0;
      end

      STATE_STALL: begin
        if (rAddr == 0) begin
          // Load first transaction
          tdata <= {rDataIm, rDataRe};
        end else if (rAddr == 1) begin
          // Start first transaction
          tvalid <= 1;
          streaming <= 1;
        end
        rAddr <= rAddr + 1;
      end

      STATE_STREAMING: begin
        // begin transactions
        if (tready && tlast) begin
          tvalid <= 0;
          streaming <= 0;
        end

        // Feed one by one, assert tlast on last
        // If tready is de-asserted during transfer, wait
        if (tready && !tlast) begin
          tdata <= {rDataIm, rDataRe};
          transI <= transI + 1; // Increment index
          rAddr <= rAddr + 1;
        end
      end
      // default: unreachable
    endcase

    // Advance next state
    currState <= nextState;
  end
endmodule
