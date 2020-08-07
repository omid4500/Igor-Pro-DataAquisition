#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function write_IPS_VISA(instr, cmd)
	Variable instr
	String cmd
	    
	VISAWrite instr, cmd + "\r"
	wait(0.01)
end

function/S read_IPS_VISA(instr)
	variable instr
	
	string out
	VISARead/T="\r" instr, out
	return out
end

function test_IPS_VISA(instr)
	Variable instr
	
	write_IPS_VISA(instr, "V")
	print read_IPS_VISA(instr)
end


// ----------------------------
//	Here is a list of commands that are supported with this magnet drive procedure:
//
//	first, the "set control" commands, as they are wisely call in the manual
//	C2	:	local and unlocked
//	C3	:	remote and unlocked
//
//	then, a set of action commands (just like on front panel)
// A0	:	hold
//	A1	:	to set point
//	A2	:	to zero
//	A4	:	clamp			(pretty radical, probably bad idea to try when at (high/any) field)
//
//	then, target commands:
//	Inn	:	set target current (amps)
//	Snn	:	set current sweep rate

function init_IPS(instr)
	variable instr
	
	variable/G IPS_VISA_address
	IPS_VISA_address = instr
	
	remote_IPS_VISA(instr)
	hold_IPS_VISA(instr)
	toSetPoint_IPS_VISA(instr)
	heaterOn_IPS_VISA(instr)	
end

function deinit_IPS(instr)
	variable instr

	variable/G IPS_VISA_address
	IPS_VISA_address = 0

	clamp_IPS_VISA(instr)
	heaterOff_IPS_VISA(instr)
	local_IPS_VISA(instr)
end

function local_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$C2")
end

function remote_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$C3")
end

function hold_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$A0")
end

function toSetPoint_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$A1")
end

function toZero_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$A2")
end

function clamp_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$A4")
end

function heaterOn_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$H1")
end

function heaterOff_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$H0")
end

function goPersistent_IPS_VISA(instr)
	variable instr
		
	write_IPS_VISA(instr,"$H0")
	wait(60)
end

function quitPersistent_IPS_VISA(instr)
	variable instr
	
	write_IPS_VISA(instr,"$H1")
	wait(60)
end

function setTargetCurrent_IPS_VISA(instr,amps)
	variable instr
	variable amps		//	amps: current in amps, including sign (negative values ok)
	
	write_IPS_VISA(instr,"$I"+num2str(amps))
end

function setTargetField_IPS_VISA(instr,tesla)
	variable instr
	variable tesla		// filed in Tesla, including sign  (negative values ok)
	
	write_IPS_VISA(instr,"$J"+num2str(tesla))
end

function setSweepRate_IPS_VISA(instr,amps)
	variable instr
	variable amps		//	amps: sweeprate in amps/min
	
	write_IPS_VISA(instr,"$S"+num2str(amps))
end

function setFieldSweepRate_IPS_VISA(instr,tesla)
	variable instr
	variable tesla		//	tesla: sweeprate in tesla/min
	
	write_IPS_VISA(instr,"$T"+num2str(tesla))
end

function setFieldSweepRatw_mTS_IPS_VISA(instr,mtesla_pre_sec)
	variable instr
	variable mtesla_pre_sec

	variable tesla = mtesla_pre_sec/1000*60
	if(tesla>0.15)
		print "sweep rate too high - reduced to 0.15 T/min and set"
		tesla=0.15
	endif	
	write_IPS_VISA(instr,"$T"+num2str(tesla))
end

function read_param_IPS_VISA(instr,val)
	variable instr
	variable val
	// interesting par's are: (also see page 33, IPS120-10 manual)
	//	0	:	output current 				Amp
	//	1	:	measured output voltage		Volt
	//	5	:	set point 						Amp
	//	6	: 	sweep rate						Amps/min
	//	7	:	output field					Tesla
	//	8	:	set point						Tesla
	//	9	:	sweep rate						Tesla/min
	//	21	:	safe current limit (neg)	Amp
	//	22	:	safe current limit (pos)	Amp
	// 23	:	lead resistance				milli Ohm
	//	24	:	magnet inductance				Henry
	write_IPS_VISA(instr,"R"+num2str(val))
	
	string in_str
	variable in_v
	
	in_str = read_IPS_VISA(instr)

	in_v = str2num(in_str[1,7])   // Pick out number
	return in_v
end
function/s IPS_Status(instrID)
	variable instrID
	string  buffer = ""
	string gpib = num2istr(getAddressGPIB(instrID))
	buffer = addJSONkeyval(buffer, "gpib_address", gpib)
	buffer = addJSONkeyval(buffer, "Field(T)", num2str(read_param_IPS_VISA(instrID, 7)))
	buffer = addJSONkeyval(buffer, "Current(A)", num2str(read_param_IPS_VISA(instrID, 0)))
	buffer = addJSONkeyval(buffer, "Ramperate(T/min)", num2str(read_param_IPS_VISA(instrID, 9)))
	return buffer
end