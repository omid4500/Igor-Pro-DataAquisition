#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function LSreadtemp(instr, channel)
	variable instr, channel
	// channels:
	//
	//	1:50K
	//	2:4K
	//	3:magnet
	//	4:magn.heater
	//	5:still
	//	6:tmc
	string cmd
	sprintf cmd "RDGK? %d" channel
	return str2num(queryInstr(instr, cmd))
end

function LSreadresistance(instr, channel)
	variable instr, channel
	string cmd
	sprintf cmd "RDGR? %d" channel
	return str2num(queryInstr(instr, cmd))
end

function LSreadstatus(instr, channel)
	variable instr, channel
	string cmd
	//returns three status bits...
	//	Bit		Bit weighting		Status indicator
	//	0		1				CS OVL
	//	1		2				VCM OVL		
	//	2		4				VMIX OVL	
	//	3		8				VDIF OVL	
	//	4		16				R. OVER	
	//	5		32				R. UNDER
	//	6		64				T. OVER	
	//	7		128			T. UNDER
	//		
	sprintf cmd "RDGST? %d" channel
	return str2num(queryInstr(instr, cmd))
end

function LSsetAutoScan(instr, channel, onoff) // onoff = 0 for off, 1 for on
	// if you turn autoscan off, it will only scan the channel specified.
	// if you turn autoscan on, the channel doesn't matter, it will scan all channels.
	variable instr, channel, onoff
	string cmd
	sprintf cmd "SCAN %d,%d" channel,onoff
	writeInstr(instr, cmd)
end

function LSreadStillHeater(instr) 
	variable instr
	string cmd = "STILL? "
	variable v = str2num(queryInstr(instr, cmd))
	v = (v/10/150)^2*120*1000
	return round(v*10)/10
end

function LSsetStillHeater(instr, mW)
	variable instr, mW
	string cmd = ""
	mW = sqrt(mW/1000*150^2/120)*10
	sprintf cmd "STILL %f" mW
	writeInstr(instr, cmd)
end

// Mixing chamber heater
function LSsetMCHeater(instr, percent, range)
	// range:
	//0:off
	//1:	31.6uA	2:	100uA
	//3:	316uA		4:	1mA
	//5:	3.16mA	6:	10mA
	//7:	31.6mA	8:	100mA
	variable instr, percent, range
	string cmd = ""
	sprintf cmd "HTRRNG %d" range
	writeInstr(instr, cmd)
	sprintf cmd "MOUT %d" percent
	writeInstr(instr, cmd)	
end

function/s LSgetStatus(instr)
	variable instr
	string  buffer = ""
	string gpib = num2istr(getAddressGPIB(instr))
	buffer = addJSONkeyval(buffer, "gpib_address", gpib)
	buffer = addJSONkeyval(buffer, "50KTemp(K)", num2str(LSreadtemp(instr, 1)))
	buffer = addJSONkeyval(buffer, "4KTemp(K)", num2str(LSreadtemp(instr, 2)))
	buffer = addJSONkeyval(buffer, "MagnetTemp(K)", num2str(LSreadtemp(instr, 3)))
	buffer = addJSONkeyval(buffer, "MagnetPersistTemp(K)", num2str(LSreadtemp(instr, 4)))
	buffer = addJSONkeyval(buffer, "StillTemp(K)", num2str(LSreadtemp(instr, 5)))
	buffer = addJSONkeyval(buffer, "MixingChamberTemp(K)", num2str(LSreadtemp(instr, 6)))

	string status = ""
	variable i
	for (i=1; i<=6; i+=1)
		status += num2str(LSreadstatus(instr, i)) + ";"
	endfor
	buffer = addJSONkeyval(buffer, "ChannelStatus", status, addquotes=1)

	buffer = addJSONkeyval(buffer, "StillHeater(mW)", num2str(LSreadStillHeater(instr)))
	return buffer
end

//function LSStartMcPID(instr, target_mK)
//	variable instr, target_mK
//	string cmd = ""
	
	//LSsetAutoScan(instr, 6, 0)
	
	// Set the heater range
	// Refer to PDF-page 132 of this document
	// https://zumbuhllab.unibas.ch/fileadmin/user_upload/zumbuhllab-unibas-ch/Files_PW/Lab_Repository/LakeShore_370AC_Manual.pdf
	// parameters mean: mixing chambe, no filter?, in units of kelvin, delay, display current=1 or power=2, heater limit range, heater resistance in ohms = 1?
//	if (target_mK < 50)
	//	print "<50"
	//	LSsetMCHeater(instr, 0, 4)
//		writeInstr(instr, "CSET 6,0,1,1,1,4,1")
//	elseif (target_mK < 100)
	//	print "<100"
	//	LSsetMCHeater(instr, 0, 5)
	//	writeInstr(instr, "CSET 6,0,1,1,1,5,1")
//	elseif (target_mK < 200)
	//	print "<200"
//		LSsetMCHeater(instr, 0, 6)
//		writeInstr(instr, "CSET 6,0,1,1,1,6,1")
//	elseif (target_mK < 600)
	//	print "<600"
	//	LSsetMCHeater(instr, 0, 7)
	//	writeInstr(instr, "CSET 6,0,1,1,1,7,1")
	//else
	//	print "Are you trying to warm up the fridge? I don't think this is going to work."
	//	return 0
//	endif
	
//	writeInstr(instr, "CMODE 1") 	// Closed Loop
	
	// Set the target temperature
//	sprintf cmd "SETP %.3f" target_mK/1000
//	writeInstr(instr, cmd)
//end
function LSStopMcPID(instr)
	variable instr
	LSsetMCHeater(instr, 0, 0)
	writeInstr(instr, "CSET 6,0,1,1,1,0,1")
	writeInstr(instr, "CMODE 4")
	writeInstr(instr, "SETP 0")
	LSsetAutoScan(instr, 6, 1)
end