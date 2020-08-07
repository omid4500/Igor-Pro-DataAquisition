#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function readDMM(instr)
	Variable instr		
	String variableWrite, variableRead    
	String response = queryInstr(instr, "read?\n")
	return str2num(response)*1000
End
