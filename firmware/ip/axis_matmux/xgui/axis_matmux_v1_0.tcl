# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  ipgui::add_param $IPINST -name "IN_COUNT_WIDTH"
  ipgui::add_param $IPINST -name "N_OUT"
  ipgui::add_param $IPINST -name "IN_WIDTH"
  set STAGE_DELAY [ipgui::add_param $IPINST -name "STAGE_DELAY"]
  set_property tooltip {Increase this to make meet timing constraints} ${STAGE_DELAY}
  set N_PARALLELISM [ipgui::add_param $IPINST -name "N_PARALLELISM"]
  set_property tooltip {PARALLELISM} ${N_PARALLELISM}

}

proc update_PARAM_VALUE.IN_COUNT_WIDTH { PARAM_VALUE.IN_COUNT_WIDTH } {
	# Procedure called to update IN_COUNT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IN_COUNT_WIDTH { PARAM_VALUE.IN_COUNT_WIDTH } {
	# Procedure called to validate IN_COUNT_WIDTH
	return true
}

proc update_PARAM_VALUE.IN_WIDTH { PARAM_VALUE.IN_WIDTH } {
	# Procedure called to update IN_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IN_WIDTH { PARAM_VALUE.IN_WIDTH } {
	# Procedure called to validate IN_WIDTH
	return true
}

proc update_PARAM_VALUE.N_OUT { PARAM_VALUE.N_OUT } {
	# Procedure called to update N_OUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_OUT { PARAM_VALUE.N_OUT } {
	# Procedure called to validate N_OUT
	return true
}

proc update_PARAM_VALUE.N_PARALLELISM { PARAM_VALUE.N_PARALLELISM } {
	# Procedure called to update N_PARALLELISM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_PARALLELISM { PARAM_VALUE.N_PARALLELISM } {
	# Procedure called to validate N_PARALLELISM
	return true
}

proc update_PARAM_VALUE.STAGE_DELAY { PARAM_VALUE.STAGE_DELAY } {
	# Procedure called to update STAGE_DELAY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STAGE_DELAY { PARAM_VALUE.STAGE_DELAY } {
	# Procedure called to validate STAGE_DELAY
	return true
}


proc update_MODELPARAM_VALUE.IN_COUNT_WIDTH { MODELPARAM_VALUE.IN_COUNT_WIDTH PARAM_VALUE.IN_COUNT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IN_COUNT_WIDTH}] ${MODELPARAM_VALUE.IN_COUNT_WIDTH}
}

proc update_MODELPARAM_VALUE.N_OUT { MODELPARAM_VALUE.N_OUT PARAM_VALUE.N_OUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_OUT}] ${MODELPARAM_VALUE.N_OUT}
}

proc update_MODELPARAM_VALUE.IN_WIDTH { MODELPARAM_VALUE.IN_WIDTH PARAM_VALUE.IN_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IN_WIDTH}] ${MODELPARAM_VALUE.IN_WIDTH}
}

proc update_MODELPARAM_VALUE.STAGE_DELAY { MODELPARAM_VALUE.STAGE_DELAY PARAM_VALUE.STAGE_DELAY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STAGE_DELAY}] ${MODELPARAM_VALUE.STAGE_DELAY}
}

