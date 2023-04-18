module fft_data_output #(
  parameter integer NFFT = 3,

  parameter integer POINT_SIZE = $pow(2, NFFT),
  parameter integer N_ELEMENTS = POINT_SIZE * 2, // RE and IM pair for each point
  parameter integer ELEMENTS_ADDR_SIZE = $clog2(N_ELEMENTS)
) (
  input wire clk,
  input wire resetn,

  // RAM interface
  input  wire [ELEMENTS_ADDR_SIZE-1:0] rAddr,
  output wire [31:0]                   rData,

  // S AXIS Interface
  output reg        tready,
  input wire        tvalid,
  input wire        tlast,
  input wire [63:0] tdata, // {IM, RE}

  output reg received // Asserted for one clk cycle when trans is done
);
  // Definitions
  // State machine states
  localparam STATE_IDLE      = 0;
  localparam STATE_BEGIN     = 1;
  localparam STATE_RECEIVING = 2;
  localparam STATE_DONE      = 3;
  
  // State machine registers
  reg [1:0]                    currState = 0;
  reg [1:0]                    nextState = 0;
  reg [ELEMENTS_ADDR_SIZE-1:0] transI    = 0;

  // Need 2 RAMs to support writing IQ at the same time,
  reg                           wEn;
  reg  [ELEMENTS_ADDR_SIZE-1:0] wAddr;
  reg  [31:0]                   wDataRe;
  reg  [31:0]                   wDataIm;
  wire [31:0]                   rDataRe;
  wire [31:0]                   rDataIm;
  ad_mem #(
    .DATA_WIDTH(32),
    .ADDRESS_WIDTH(ELEMENTS_ADDR_SIZE-1)
  ) oRamRe (
    .clka(clk),
    .wea(wEn),
    .addra(wAddr),
    .dina(wDataRe),
    .clkb(clk),
    .reb(resetn && rAddr[0] == 1'b0),
    .addrb(rAddr >> 1),
    .doutb(rDataRe)
  );
  ad_mem #(
    .DATA_WIDTH(32),
    .ADDRESS_WIDTH(ELEMENTS_ADDR_SIZE-1)
  ) oRamIm (
    .clka(clk),
    .wea(wEn),
    .addra(wAddr),
    .dina(wDataIm),
    .clkb(clk),
    .reb(resetn && rAddr[0] == 1'b1),
    .addrb(rAddr >> 1),
    .doutb(rDataIm)
  );

  assign rData = rAddr[0] == 1'b0 ? rDataRe : rDataIm;

  // Next state logic
  always @(*) begin
    if (resetn == 0) begin
      nextState = STATE_IDLE;

    end else if (currState == STATE_IDLE) begin
      if (tvalid) begin
        nextState = STATE_BEGIN;
      end else begin
        nextState = STATE_IDLE;
      end

    end else if (currState == STATE_BEGIN) begin
      nextState = STATE_RECEIVING;

    end else if (currState == STATE_RECEIVING) begin
      if (transI == POINT_SIZE-1 && tvalid) begin
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

  // Execution
  always @(posedge clk) begin
    case (currState)
      STATE_IDLE: begin
        tready <= 0;
        transI <= 0;
        received <= 0;
        wEn <= 0;
        wAddr <= 0;
      end

      STATE_BEGIN: begin
        tready <= 1;
      end

      STATE_RECEIVING: begin
        if (tvalid) begin
          // Transaction
          wEn <= 1;
          wDataRe <= tdata[31:0];
          wDataIm <= tdata[63:32];
          transI <= transI + 1;

          if (transI != 0) begin
            wAddr <= wAddr + 1;
          end
        end else begin
          wEn <= 0;
        end
      end

      STATE_DONE: begin
        wEn <= 0;
        received <= 1; // One clk pulse
      end
      
      // default: // Unreachable
    endcase

    // advance state
    currState <= nextState;
  end

endmodule