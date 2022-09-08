source $ad_hdl_dir/projects/common/zcu111/zcu111_system_bd.tcl

source $ad_hdl_dir/projects/basic_gpio/common/basic_gpio_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

# ad_mem_hp0_interconnect $sys_cpu_clk sys_ps8/S_AXI_HP0

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/mem_init_sys.txt"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9

sysid_gen_sys_init_file