# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

global VIVADO_IP_LIBRARY

adi_ip_create axi_fft
adi_ip_files axi_fft [list \
    "$ad_hdl_dir/library/common/up_axi.v" \
    "axi_fft.v"]

adi_ip_properties axi_fft

ipx::save_core [ipx::current_core]