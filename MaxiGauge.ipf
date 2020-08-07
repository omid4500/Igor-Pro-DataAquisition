#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function init_MaxiGauge()
	VDTOperationsPort2 COM3
	VDT2 baud=9600, stopbits=1, databits=8, parity=0, in=0, out=0, echo=1	//Set protocol
end

function deinit_MaxiGauge()
	VDTClosePort2 COM3
end

function send_MaxiGauge(cmd)
	string cmd
	
	vdtwrite2/O=3 cmd+"\r"
	if(V_VDT==0)
			print "IPS write time out ..."
	endif
end

function/S read_MaxiGauge()

	string out
	vdtread2/Q/O=3/T="\r" out
	if(V_VDT==0)
			print "IPS read time out ..."
	endif
	return out
end

//-----------------------

function read_pressure(channel)
	variable channel
	
	string cmd, out
	cmd = "PR"+num2str(channel)
	send_MaxiGauge(cmd)
	
	out = read_MaxiGauge()
	//print out 
	
	cmd = "\x05"
	send_MaxiGauge(cmd)
	
	out = read_MaxiGauge()
	
	variable statusV, valueV
	sscanf out, "%d,%f\r", statusV, valueV
	
	if(statusV==0)
		return valueV
	else
		print "Error \""+num2str(statusV)+"\" from page 88 in the MaxiGauge manual"
		return nan
	endif
end
