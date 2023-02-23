# load script
source ../../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

# get the value of the parameter TWOLANES from make command, and if not given, then take value 1
set twolanes_param [get_env_param  TWOLANES  1]

# will be printed in the vivado log
puts "\nGot TWOLANES = $twolanes_param\n"

adi_project cn0577_zed 0 [list \
  TWOLANES $twolanes_param \
]
adi_project_files cn0577_zed [list \
  "system_top.v" \
  "system_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/ad_data_clk.v" \
  "$ad_hdl_dir/library/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/common/zed/zed_system_constr.xdc"]

adi_project_run cn0577_zed
