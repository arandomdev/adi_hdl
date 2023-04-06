`timescale 1ns / 1ps

module axi_loopback_test #(
  parameter ID = 0
) (
  //axi interface
  input                   s_axi_aclk,
  input                   s_axi_aresetn,
  input                   s_axi_awvalid,
  input       [15:0]      s_axi_awaddr,
  input       [ 2:0]      s_axi_awprot,
  output                  s_axi_awready,
  input                   s_axi_wvalid,
  input       [31:0]      s_axi_wdata,
  input       [ 3:0]      s_axi_wstrb,
  output                  s_axi_wready,
  output                  s_axi_bvalid,
  output      [ 1:0]      s_axi_bresp,
  input                   s_axi_bready,
  input                   s_axi_arvalid,
  input       [15:0]      s_axi_araddr,
  input       [ 2:0]      s_axi_arprot,
  output                  s_axi_arready,
  output                  s_axi_rvalid,
  output      [ 1:0]      s_axi_rresp,
  output      [31:0]      s_axi_rdata,
  input                   s_axi_rready
);
  // Definitions
  // up_axi emits DWORD addresses, hence 14 bit addresses
  localparam [13:0] ADDR_VERSION = 'h0000;
  localparam [13:0] ADDR_ID = 'h0001;
  localparam [13:0] ADDR_SCRATCH = 'h0002;
  localparam [13:0] ADDR_RESET  = 'h0020;

  localparam [31:0] DEFAULT_SCRATCH = 32'h00000000;

  // Registers, 32bit words
  reg [31:0] reg_version = 32'h00000001;
  reg [31:0] reg_id = ID;
  reg [31:0] reg_scratch = DEFAULT_SCRATCH;

  // Internal connections for up_axi
  wire up_clk;
  reg up_resetn = 1'b0;

  wire        up_rreq_s;
  reg         up_rack;
  wire [13:0] up_raddr_s;
  reg  [31:0] up_rdata;

  wire        up_wreq_s;
  reg         up_wack;
  wire [13:0] up_waddr_s;
  wire [31:0] up_wdata_s;
  
  // Assignments
  assign up_clk = s_axi_aclk;

  // AXI interface Driver
  up_axi #(
    .AXI_ADDRESS_WIDTH(16)
  ) i_up_axi (
    // AXI Interface
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
    // Write Interface
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    // Read Interface
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

  // registers read
  always @(posedge up_clk) begin
    if (up_resetn == 1'b0) begin
      up_rack <= 'd0;
      up_rdata <= 'd0;
    end else begin
      up_rack <= up_rreq_s;

      if (up_rreq_s == 1'b1) begin
        case (up_raddr_s)
          ADDR_VERSION: up_rdata <= reg_version;
          ADDR_ID: up_rdata <= reg_id;
          ADDR_SCRATCH: up_rdata <= reg_scratch;
          default: up_rdata <= 'd0;
        endcase
      end else begin
        up_rdata <= 'd0;
      end
    end
  end

  // registers write
  always @(posedge up_clk) begin
    if (up_resetn == 1'b0) begin
      // TODO: Reset registers
      reg_scratch <= DEFAULT_SCRATCH;
    end else begin
      if (up_wreq_s == 1'b1) begin
        case (up_waddr_s)
          ADDR_SCRATCH: reg_scratch <= up_wdata_s;
        endcase
      end
    end
  end

  // writing reset
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
