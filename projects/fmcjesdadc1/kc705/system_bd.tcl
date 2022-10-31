
source $ad_hdl_dir/projects/common/kc705/kc705_system_bd.tcl
source ../common/fmcjesdadc1_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/mem_init_sys.txt"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9

set sys_cstring "RX:M=$ad_project_params(RX_JESD_M)\
L=$ad_project_params(RX_JESD_L)\
S=$ad_project_params(RX_JESD_S)\
NP=$ad_project_params(RX_JESD_NP)"
sysid_gen_sys_init_file $sys_cstring

ad_ip_parameter axi_ad9250_dma CONFIG.DMA_DATA_WIDTH_DEST 512
ad_ip_parameter axi_ad9250_dma CONFIG.FIFO_SIZE 32

