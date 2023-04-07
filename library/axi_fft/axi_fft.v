// Top module for the axi fft core.

module axi_fft #(
  parameter NFFT = 8,
  parameter PERI_ID = 0,
  parameter [31:0] IDENT = 32'h46465443 // FFTC
) (
  // AXI Slave Interface
  input              s_axi_aclk,
  input              s_axi_aresetn,
  input              s_axi_awvalid,
  input       [15:0] s_axi_awaddr,
  input       [ 2:0] s_axi_awprot,
  output             s_axi_awready,
  input              s_axi_wvalid,
  input       [31:0] s_axi_wdata,
  input       [ 3:0] s_axi_wstrb,
  output             s_axi_wready,
  output             s_axi_bvalid,
  output      [ 1:0] s_axi_bresp,
  input              s_axi_bready,
  input              s_axi_arvalid,
  input       [15:0] s_axi_araddr,
  input       [ 2:0] s_axi_arprot,
  output             s_axi_arready,
  output             s_axi_rvalid,
  output      [ 1:0] s_axi_rresp,
  output      [31:0] s_axi_rdata,
  input              s_axi_rready,

  // AXIS Master Interface for FFT Core data input
  input  wire        i_tready,
  output wire        i_tvalid,
  output wire        i_tlast,
  output wire [63:0] i_tdata,

  // AXIS Slave Interface for FFT Core data output
  output wire        o_tready,
  input  wire        o_tvalid,
  input  wire        o_tlast,
  input  wire [63:0] o_tdata,

  // AXIS Slave Interface for FFT Core config
  output wire       c_tready,
  input  wire       c_tvalid,
  input  wire       c_tlast,
  input  wire [8:0] c_tdata
);
  // Definitions
  // up_axi emits DWORD addresses, hence 14 bit addresses
  localparam [13:0] ADDR_VERSION =    'h0000;
  localparam [13:0] ADDR_PERI_ID =    'h0001;
  localparam [13:0] ADDR_SCRATCH =    'h0002;
  localparam [13:0] ADDR_IDENT =      'h0003;
  localparam [13:0] ADDR_FFT_CONFIG = 'h0004;

  localparam [13:0] ADDR_RESET =      'h0020;
  localparam [13:0] ADDR_INPUT_TRIG = 'h0021;
  localparam [13:0] ADDR_CONFIG_TRIG = 'h0022;

  localparam [13:0] ADDR_INPUT_START = 'h0040;
  localparam [13:0] ADDR_INPUT_END = ADDR_INPUT_START + (NFFT*2);
  localparam [13:0] ADDR_OUTPUT_START = ADDR_INPUT_END;
  localparam [13:0] ADDR_OUTPUT_END = ADDR_OUTPUT_START + (NFFT*2);

  localparam [31:0] DEFAULT_SCRATCH = 32'h00000000;
  localparam [31:0] DEFAULT_FFT_CONFIG = 32'h00000001;

  // AXI registers, 32bit words
  reg [31:0] reg_version = 32'h00000001;
  reg [31:0] reg_peri_id = PERI_ID;
  reg [31:0] reg_scratch = DEFAULT_SCRATCH;
  reg [31:0] reg_ident = IDENT;
  reg [31:0] reg_fftConfig = DEFAULT_FFT_CONFIG;

  // Internal connections for up_axi
  wire up_clk = s_axi_aclk; // same as AXI
  reg up_resetn = 1'b0;

  wire        up_rreq_s;
  reg         up_rack;
  wire [13:0] up_raddr_s;
  reg  [31:0] up_rdata;

  wire        up_wreq_s;
  reg         up_wack;
  wire [13:0] up_waddr_s;
  wire [31:0] up_wdata_s;

  // Internal connections for fft_data_input
  reg [$clog2(NFFT*2)-1:0] iWAddr;
  reg [31:0]               iWData;
  reg                      iWEn;
  reg                      iTrig;
  wire                     iStreaming;

  // Internal connections for fft_data_output
  wire [$clog2(NFFT*2)-1:0] oRAddr;
  wire [31:0]               oRData;
  wire                      oReceiving;

  // constant assignment to output address for same clock reads
  assign oRAddr = (up_resetn &&
                   up_rreq_s &&
                   up_raddr_s >= ADDR_OUTPUT_START &&
                   up_raddr_s < ADDR_OUTPUT_END) ?
                   up_raddr_s - ADDR_OUTPUT_START : 0;

  // Internal connections for fft_config
  reg cCommit;

  // Instances
  up_axi #(
    .AXI_ADDRESS_WIDTH(16)
  ) i_up_axi (
    .up_rstn (s_axi_aresetn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

  fft_data_input #(
    .NFFT(NFFT)
  ) i_fft_data_input (
    .clk(up_clk),
    .resetn(up_resetn),
    .wAddr(iWAddr),
    .wData(iWData),
    .wEn(iWEn),
    .tready(i_tready),
    .tvalid(i_tvalid),
    .tlast(i_tlast),
    .tdata(i_tdata),
    .trig(iTrig),
    .streaming(iStreaming));

  fft_data_output #(
    .NFFT(NFFT)
  ) i_fft_data_output (
    .clk(up_resetn),
    .resetn(up_resetn),
    .rAddr(orAddr),
    .rData(oRData),
    .tready(o_tready),
    .tvalid(o_tvalid),
    .tlast(o_tlast),
    .tdata(o_tdata),
    .receiving(oReceiving));

  fft_config i_fft_config (
    .clk(up_clk),
    .resetn(up_resetn),
    .scaleSch(reg_fftConfig[8:1]),
    .forward(reg_fftConfig[0]),
    .tready(c_tready),
    .tvalid(c_tvalid),
    .tlast(c_tlast),
    .tdata(c_tdata),
    .commit(cCommit)
  );

  // registers read
  always @(posedge up_clk) begin
    if (up_resetn == 1'b0) begin
      up_rack <= 'd0;
      up_rdata <= 'd0;
    end else begin
      up_rack <= up_rreq_s;

      if (up_rreq_s == 1'b1) begin
        if (up_raddr_s >= ADDR_OUTPUT_START &&
            up_raddr_s < ADDR_OUTPUT_END) begin
          // FFT Output read
          up_rdata <= oRData;          
        end else begin
          // Register read
          case (up_raddr_s)
            ADDR_VERSION: up_rdata <= reg_version;
            ADDR_PERI_ID: up_rdata <= reg_peri_id;
            ADDR_SCRATCH: up_rdata <= reg_scratch;
            ADDR_IDENT: up_rdata <= reg_ident;
            ADDR_FFT_CONFIG: up_rdata <= reg_fftConfig;
            default: up_rdata <= 'd0;
          endcase
        end
      end else begin
        up_rdata <= 'd0;
      end
    end
  end

  // registers write
  always @(posedge up_clk) begin
    if (up_resetn == 1'b0) begin
      reg_scratch <= DEFAULT_SCRATCH;
    end else begin
      if (up_wreq_s == 1'b1) begin
        case (up_waddr_s)
          ADDR_SCRATCH: reg_scratch <= up_wdata_s;
          ADDR_FFT_CONFIG: reg_fftConfig <= up_wdata_s;
        endcase
      end
    end
  end

  // Write FFT input
  always @(posedge up_clk) begin
    if (up_resetn == 1'b1 &&
      up_waddr_s &&
      up_waddr_s >= ADDR_INPUT_START &&
      up_waddr_s < ADDR_INPUT_END) begin
        iWAddr <= up_waddr_s - ADDR_INPUT_START;
        iWData <= up_wdata_s;
        iWEn <= 1;
      end else begin
        iWEn <= 0;
      end
  end

  // Write triggers
  always @(posedge up_clk) begin
    if (up_resetn == 1'b1 && up_waddr_s) begin
      case (up_waddr_s)
        ADDR_INPUT_TRIG: iTrig <= 1;
        ADDR_CONFIG_TRIG: cCommit <= 1;
        default: begin
          iTrig <= 0;
          cCommit <= 0;
        end
      endcase
    end else begin
      iTrig <= 0;
      cCommit <= 0;
    end
  end

  // Writing reset
  always @(posedge up_clk) begin
    if (s_axi_aresetn == 1'b0) begin
      up_wack <= 'd0;
      up_resetn <= 1'd0;
    end else begin
      up_wack <= up_wreq_s;
      
      if ((up_wreq_s == 1'b1) && (up_waddr_s == ADDR_RESET)) begin
        up_resetn <= up_wdata_s[0];
      end else begin
        up_resetn <= 1'd1;
      end
    end
  end
endmodule
