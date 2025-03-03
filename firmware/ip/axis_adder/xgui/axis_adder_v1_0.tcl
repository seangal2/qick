# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set N_DDS [ipgui::add_param $IPINST -name "N_DDS" -parent ${Page_0}]
  set_property tooltip {N DDS - all inputs should be the same and match this value} ${N_DDS}
  set N_IN [ipgui::add_param $IPINST -name "N_IN" -parent ${Page_0}]
  set_property tooltip {Number of input streams to add} ${N_IN}


}

proc update_PARAM_VALUE.N_DDS { PARAM_VALUE.N_DDS } {
	# Procedure called to update N_DDS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_DDS { PARAM_VALUE.N_DDS } {
	# Procedure called to validate N_DDS
	return true
}

proc update_PARAM_VALUE.N_IN { PARAM_VALUE.N_IN } {
	# Procedure called to update N_IN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_IN { PARAM_VALUE.N_IN } {
	# Procedure called to validate N_IN
	return true
}


proc update_MODELPARAM_VALUE.N_IN { MODELPARAM_VALUE.N_IN PARAM_VALUE.N_IN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_IN}] ${MODELPARAM_VALUE.N_IN}
}

proc update_MODELPARAM_VALUE.N_DDS { MODELPARAM_VALUE.N_DDS PARAM_VALUE.N_DDS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_DDS}] ${MODELPARAM_VALUE.N_DDS}
}

