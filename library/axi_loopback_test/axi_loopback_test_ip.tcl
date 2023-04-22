# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create axi_loopback_test
adi_ip_files axi_loopback_test [list \
    "$ad_hdl_dir/library/common/up_axi.v" \
    "axi_loopback_test.v"]

adi_ip_properties axi_loopback_test

ipx::save_core [ipx::current_core]