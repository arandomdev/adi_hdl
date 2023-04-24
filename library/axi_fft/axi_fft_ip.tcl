# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create axi_fft
adi_ip_files axi_fft [list \
    "$ad_hdl_dir/library/common/up_axi.v" \
    "$ad_hdl_dir/library/common/ad_mem.v" \
    "fft_data_input.v" \
    "fft_data_output.v" \
    "fft_config.v" \
    "axi_fft.v"]

adi_ip_properties axi_fft

## Interface definitions
adi_add_bus "m_axis_i" "master" \
    "xilinx.com:interface:axis_rtl:1.0" \
    "xilinx.com:interface:axis:1.0" \
    {
        {"m_axis_i_tready" "TREADY"} \
        {"m_axis_i_tvalid" "TVALID"} \
        {"m_axis_i_tlast" "TLAST"} \
        {"m_axis_i_tdata" "TDATA"} \
    }

adi_add_bus "s_axis_o" "slave" \
    "xilinx.com:interface:axis_rtl:1.0" \
    "xilinx.com:interface:axis:1.0" \
    {
        {"s_axis_o_tready" "TREADY"} \
        {"s_axis_o_tvalid" "TVALID"} \
        {"s_axis_o_tlast" "TLAST"} \
        {"s_axis_o_tdata" "TDATA"} \
    }

adi_add_bus "m_axis_c" "master" \
    "xilinx.com:interface:axis_rtl:1.0" \
    "xilinx.com:interface:axis:1.0" \
    {
        {"m_axis_c_tready" "TREADY"} \
        {"m_axis_c_tvalid" "TVALID"} \
        {"m_axis_c_tlast" "TLAST"} \
        {"m_axis_c_tdata" "TDATA"} \
    }

adi_add_bus_clock s_axi_aclk s_axi:m_axis_i:s_axis_o:m_axis_c s_axi_aresetn

ipx::save_core [ipx::current_core]
