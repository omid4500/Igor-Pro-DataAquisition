#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function test_AVS_VISA(instr)
	variable instr
	
	string cmd
	
	cmd = "*IDN?\n"
	write_AVS_VISA(instr, cmd)
	
	print read_AVS_VISA(instr)
End

function write_AVS_VISA(instr, cmd)
	variable instr
	string cmd
	
	VISAWrite instr, cmd
end

function/S read_AVS_VISA(instr)
	variable instr
	
	wait(0.01)
	string stringRead
	VISARead/T="\n" instr, stringRead
	return stringRead
end

//------------------------------------

function local_AVS_VISA(instr)
	variable instr
	
	string cmd
	cmd = "REM0"
	write_AVS_VISA(instr, cmd)
end

function remote_AVS_VISA(instr)
	variable instr
	
	string cmd
	cmd = "REM1"
	write_AVS_VISA(instr, cmd)
end

function zero_AVS_VISA(instr)
	variable instr

	string cmd
	cmd = "INP0"
	write_AVS_VISA(instr, cmd)
End

function measure_AVS_VISA(instr)
	variable instr

	string cmd
	cmd = "INP1"
	write_AVS_VISA(instr, cmd)
End

function setChannel_AVS_VISA(instr, channel)
	variable instr
	variable channel
	
	string cmd
	cmd = "MUX"+num2str(channel)
	write_AVS_VISA(instr, cmd)
end

function readChannel_AVS_VISA(instr)
	variable instr
	
	string cmd
	cmd = "MUX?"
	write_AVS_VISA(instr, cmd)
	print read_AVS_VISA(instr)
end

function readRes_AVS_VISA(instr)
	variable instr
	
	string cmd
	cmd = "ADC"
	write_AVS_VISA(instr, cmd)
	cmd = "RES?"
	write_AVS_VISA(instr, cmd)
	
	string stringRead
	stringRead = read_AVS_VISA(instr)
	variable val
	sscanf stringRead, "RES %f", val
	return val
end