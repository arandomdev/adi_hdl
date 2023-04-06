module fft_data_feeder #(
  parameter N_SAMPLE_BITS = 32,
  parameter NFFT = 8
) (
  input wire clk,
  input wire aresetn,

  // RAM write interface
  input wire [$clog2(NFFT):0] wAddr,
  input wire                  wData,
  input wire                  wEn,


  input wire feedTrig, // Feed trigger, single clk pulse
  output reg feeding // asserted when feeding, and ram is locked
);
  // Definitions
  // State machine state
  localparam STATE_IDLE = 0;
  localparam STATE_WAIT_READY = 1;
  localparam STATE_FEEDING = 2;

  // State machine registers
  reg [1:0] currState = 0;
  reg [1:0] nextState = 0;
  reg [$clog2(NFFT):0] feedI = 0; // current address of feeding
  
  reg [N_SAMPLE_BITS-1:0] ram [NFFT-1:0];

  // RAM write
  always @(posedge clk) begin
    // Locks when feeding
    if (currState == STATE_IDLE && wEn == 1'b1) begin
      ram[wAddr] = wData;
    end
  end

  // State machine next state logic
  always @(*) begin
    
  end
 
endmodule