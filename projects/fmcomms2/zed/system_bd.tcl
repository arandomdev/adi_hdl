source $ad_hdl_dir/projects/common/zed/zed_system_bd.tcl
source ../common/fmcomms2_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

set mem_init_sys_path [get_env_param ADI_PROJECT_DIR ""]mem_init_sys.txt;

# lookback_test
ad_ip_instance axi_loopback_test axi_loopback_test_0
ad_connect sys_cpu_clk axi_loopback_test_0/s_axi_aclk
ad_connect sys_cpu_resetn axi_loopback_test_0/s_axi_aresetn
ad_cpu_interconnect 0x44000000 axi_loopback_test_0

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/$mem_init_sys_path"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9

sysid_gen_sys_init_file

ad_ip_parameter axi_ad9361 CONFIG.ADC_INIT_DELAY 23

ad_ip_parameter axi_ad9361 CONFIG.TDD_DISABLE 1

