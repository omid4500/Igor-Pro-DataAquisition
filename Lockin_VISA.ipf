#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function Lockin_Ph_VISA(instr)
	Variable instr
	String response = queryInstr(instr, "PHA.")
	return str2num(response)
end
function Lockin_M_VISA(instr)
	Variable instr
	String response = queryInstr(instr, "MAG.")
	return str2num(response)
end
function Lockin_X_VISA(instr)
	Variable instr
	String response = queryInstr(instr, "X.")
	return str2num(response)
end
function Lockin_Y_VISA(instr)
	Variable instr
	String response = queryInstr(instr, "Y.")
	return str2num(response)
end
function Lockin_GetSensitivity(instr)
	variable instr
	return str2num(queryInstr(instr, "SEN."))
end
function Lockin_GetTimeConstant(instr)
	variable instr
	return str2num(queryInstr(instr, "TC."))
end
function Lockin_GetOscillationAmplitude(instr)
	variable instr
	return str2num(queryInstr(instr, "OA."))
end
function Lockin_GetOscillationFrequency(instr)
	variable instr
	return str2num(queryInstr(instr, "OF."))
end
function Lockin_SetOscillationAmplitude(instr, v)
	variable instr, v
	string cmd = ""
	sprintf cmd "OA %f" v
	writeInstr(instr, cmd)
end
function Lockin_SetSensitivity(instr, sen)
	variable instr, sen
	string cmd = ""
	sprintf cmd "SEN %d" sen
	writeInstr(instr, cmd)
end

function/s Lockin_Status(instr)
	variable instr
	string  buffer = ""
	string gpib = num2istr(getAddressGPIB(instr))
	buffer = addJSONkeyval(buffer, "gpib_address", gpib)
	buffer = addJSONkeyval(buffer, "sensitivity(V)", num2str(Lockin_GetSensitivity(instr)))
	buffer = addJSONkeyval(buffer, "time_constant(s)", num2str(Lockin_GetTimeConstant(instr)))
	buffer = addJSONkeyval(buffer, "oscillation_amplitude(V)", num2str(Lockin_GetOscillationAmplitude(instr)))
	buffer = addJSONkeyval(buffer, "oscillation_frequency(Hz)", num2str(Lockin_GetOscillationFrequency(instr)))
	return buffer
end