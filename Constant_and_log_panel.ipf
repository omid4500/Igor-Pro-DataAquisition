#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function init_Constant_and_log_panel()
	variable/G max_number_of_constants = 30
	variable/G number_of_constants = 1

	make/T/O/N=(max_number_of_constants) constant_name
	constant_name = ""

	make/O/N=(max_number_of_constants) constant_value
	constant_value = nan
	
	make/T/O/N=(max_number_of_constants) constant_desc
	constant_desc = ""
	
	constant_name[0] = "G0"
	constant_value[0] = 7.748091e-5
	constant_desc[0] = "Conductnace quantum"
	
	// edit constant_name,constant_value,constant_desc	
end

Window Constant_and_log_panel() : Panel
	variable/G number_of_constants
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1086.6,456,1525.8,516) as "Constants and log data"
	ModifyPanel cbRGB=(24576,24576,65300)
	SetVariable number_of_constants,pos={8,12},size={120,14},proc=set_number_of_constants,title="Number of constants:"
	SetVariable number_of_constants,limits={0,max_number_of_constants,1},value= number_of_constants
	Button init_button, pos={160,12}, size={40,14}, proc=init_constants, title="Initialize"
	
	create_Constant_and_log_panel()
	set_number_of_constants("",number_of_constants,"","")
EndMacro

function init_constants(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if(B_Struct.eventCode==1)
		variable/G number_of_constants
		wave/T constant_name
		wave constant_value
	
		variable i
		for(i=0;i<number_of_constants;i+=1)
			variable/G $(constant_name[i])=constant_value[i]		
		endfor
	endif
end

function create_Constant_and_log_panel()
	variable/G max_number_of_constants
	
	wave/T constant_name
	wave/T constant_desc
	wave constant_value
	
	
	variable i
	for(i=0;i<max_number_of_constants;i+=1)
		SetVariable $("const_name_"+num2str(i)), value=constant_name[i], title="Name: ", size={90,14}, pos={15,35+i*20}, disable=1//, proc=constant_name_was_set
		SetVariable $("const_val_"+num2str(i)), value=constant_value[i], size={110.00,14}, pos={110.00,35+i*20}, disable=1,title="value: "
		SetVariable $("const_desc_"+num2str(i)), value=constant_desc[i], title="description: ", size={200,14}, pos={230,35+i*20}, disable=1//, proc=constant_val_was_set
	endfor
end

function set_number_of_constants(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	//	print ctrlName,varNum,varStr,varName
	
	variable/G max_number_of_constants

	variable i
	for(i=0;i<max_number_of_constants;i+=1)
		SetVariable $("const_name_"+num2str(i)), disable=1
		SetVariable $("const_val_"+num2str(i)), disable=1
		SetVariable $("const_desc_"+num2str(i)), disable=1
		
		if(i<varNum)
			SetVariable $("const_name_"+num2str(i)), disable=0
			SetVariable $("const_val_"+num2str(i)), disable=0
			SetVariable $("const_desc_"+num2str(i)), disable=0
		endif
	endfor
	
	GetWindow kwTopWin wsize
	movewindow V_left, V_top, V_right, V_top+40+20*varNum
end