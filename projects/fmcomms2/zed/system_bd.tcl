source $ad_hdl_dir/projects/common/zed/zed_system_bd.tcl
source ../common/fmcomms2_bd.tcl
source $ad_hdl_dir/projects/scripts/adi_pd.tcl

set mem_init_sys_path [get_env_param ADI_PROJECT_DIR ""]mem_init_sys.txt;

# AXI_FFT
# create cores
# SCALE_SCH_WIDTH = 2*ceil(NFFT/2)
# CONFIG_WIDTH = SCALE_SCH_WIDTH + 1, Round up to multiple of 8
ad_ip_instance axi_fft axi_fft_0
ad_ip_parameter axi_fft_0 CONFIG.NFFT 10
ad_ip_parameter axi_fft_0 CONFIG.SCALE_SCH_WIDTH 10
ad_ip_parameter axi_fft_0 CONFIG.CONFIG_WIDTH 16

ad_ip_instance xfft xfft_0
ad_ip_parameter xfft_0 CONFIG.transform_length 1024
ad_ip_parameter xfft_0 CONFIG.implementation_options pipelined_streaming_io
ad_ip_parameter xfft_0 CONFIG.run_time_configurable_transform_length false
ad_ip_parameter xfft_0 CONFIG.data_format floating_point
ad_ip_parameter xfft_0 CONFIG.output_ordering natural_order
ad_ip_parameter xfft_0 CONFIG.aresetn true

# clock, reset, and address
ad_connect sys_cpu_clk axi_fft_0/s_axi_aclk
ad_connect sys_cpu_resetn axi_fft_0/s_axi_aresetn
ad_connect sys_cpu_clk xfft_0/aclk
ad_connect sys_cpu_resetn xfft_0/aresetn
ad_cpu_interconnect 0x44000000 axi_fft_0

# AXIS connections
ad_connect axi_fft_0/m_axis_i xfft_0/s_axis_data
ad_connect xfft_0/m_axis_data axi_fft_0/s_axis_o
ad_connect axi_fft_0/m_axis_c xfft_0/s_axis_config

#system ID
ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/$mem_init_sys_path"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9

sysid_gen_sys_init_file

ad_ip_parameter axi_ad9361 CONFIG.ADC_INIT_DELAY 23

ad_ip_parameter axi_ad9361 CONFIG.TDD_DISABLE 1

