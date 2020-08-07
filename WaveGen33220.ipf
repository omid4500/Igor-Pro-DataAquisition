#pragma rtGlobals=1		// Use modern global access method.

function SetWaveGenDC(WaveGen_VISA_address,value)	//dc-offset in volts
	variable WaveGen_VISA_address,value 
	String variableWrite, variableRead
	sprintf variableWrite,"VOLT:OFFS %f V",value
	VISAWrite WaveGen_VISA_address, variableWrite
end

