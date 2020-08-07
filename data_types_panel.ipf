#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function init_Data_Types_panel()
	variable/G max_number_of_measurements = 15
	
	make/T/O/N=(max_number_of_measurements) meas_name
	meas_name = ""
	
	make/T/O/N=(max_number_of_measurements) meas_device
	meas_device = ""
	
	make/O/N=(max_number_of_measurements) meas_device_ID
	meas_device_ID = 0
	
	make/T/O/N=(max_number_of_measurements) meas_type
	meas_type = ""
	
	make/O/N=(max_number_of_measurements) meas_type_ID
	meas_type_ID = 0

	make/T/O/N=(max_number_of_measurements) calc_eq
	calc_eq = "V["+num2str(p)+"]"

	make/O/N=(max_number_of_measurements) meas_record
	meas_record = 1

	make/O/N=(max_number_of_measurements) meas_plot
	meas_plot = 1

	make/O/N=(max_number_of_measurements) meas_log
	meas_log = 0

	variable/G number_of_measurements = 0
	
//	edit meas_name,meas_device,meas_device_ID,meas_type,meas_type_ID,meas_log
end

Window Data_Types_panel() : Panel

	variable/G max_number_of_measurements
	variable/G number_of_measurements
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(391.2,57.6,950,100) as "Data Types"
	ModifyPanel cbRGB=(24576,24576,65280)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (24576,24576,65280)
	SetDrawEnv save
	
	SetVariable number_of_measurements,pos={15,12},size={160,14},proc=set_number_of_measurements,title="# of measurements:"
	SetVariable number_of_measurements,limits={0,max_number_of_measurements,1},value= number_of_measurements
	
	create_Data_Types_panel()
	update_panel()
end

function create_Data_Types_panel()
	variable/G max_number_of_measurements
	variable/G number_of_measurements

	wave/T meas_name
	wave/T meas_device
	wave meas_device_ID
	wave/T meas_type
	wave/T calc_eq
	wave meas_log
	wave meas_plot
	wave meas_record

	variable i
	for(i=0;i<max_number_of_measurements;i+=1)
		string name
		if(i<10)
			name = "  "+num2str(i)
		else
			name = num2str(i)
		endif
		
		SetVariable $("ctr_Name_"+num2str(i)), value=meas_name[i], title=name, pos={5,35+i*20}, size={60,14}, disable=1		
		
		PopupMenu $("device"+num2str(i)),pos={110,35+20*i},size={70,14},bodyWidth=70,proc=set_Device,title="Device:"
		PopupMenu $("device"+num2str(i)),value=get_list_GPIB_devices(), disable=1, mode = meas_device_ID[i]+1

		PopupMenu $("datatype"+num2str(i)),pos={200,35+20*i},size={60,14},bodyWidth=70,proc=set_MeasType,title=" "
		PopupMenu $("datatype"+num2str(i)),value="", disable=1
	
		SetVariable $("calc_"+num2str(i)), value=calc_eq[i], title="M["+num2str(i)+"]=", pos={270,35+i*20}, size={120,14}, disable=1

		
		CheckBox $("log_disp"+num2str(i)), pos={400,35+20*i},size={80,14},bodyWidth=70,proc=set_meas_log,title="log "
		CheckBox $("log_disp"+num2str(i)), side=1, disable=1, value=meas_log[i]
		
		CheckBox $("plot_disp"+num2str(i)), pos={450,35+20*i},size={80,14},bodyWidth=70,proc=set_meas_plot,title="plot"
		CheckBox $("plot_disp"+num2str(i)), side=1, disable=1, value=meas_plot[i]

		CheckBox $("record_disp"+num2str(i)), pos={500,35+20*i},size={80,14},bodyWidth=70,proc=set_meas_record,title="recd"
		CheckBox $("record_disp"+num2str(i)), side=1, disable=1, value=meas_record[i]
		
	endfor
end

function/T get_list_GPIB_devices()
	string/G S_list_GPIB_devices
	return S_list_GPIB_devices
end

function update_panel()
	variable/G max_number_of_measurements
	variable/G number_of_measurements
	
	wave/T meas_device
	wave meas_device_ID
	
	wave/T meas_type
	wave meas_type_ID
	
	set_number_of_measurements("",number_of_measurements,"","")


	string ctrlName, popStr
	variable popNum
	
	variable i
	for(i=0;i<max_number_of_measurements;i+=1)

//		set_DeviceType
		ctrlName = "device"+num2str(i)
		popNum = meas_device_ID[i] + 1
		popStr = meas_device[i]
		set_Device(ctrlName,popNum,popStr)
		
//		set_MeasType
		popNum = meas_type_ID[i] + 1
		PopupMenu $("datatype"+num2str(i)),mode=popNum
		
	endfor
end

function set_number_of_measurements(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
//	print ctrlName,varNum,varStr,varName

	variable/G max_number_of_measurements
	variable/G number_of_measurements
	
	variable i
	for(i=0;i<max_number_of_measurements;i+=1)
		SetVariable $("ctr_Name_"+num2str(i)), disable=1
		PopupMenu $("datatype"+num2str(i)), disable=1
		PopupMenu $("device"+num2str(i)), disable=1
		SetVariable $("calc_"+num2str(i)), disable=1
		CheckBox $("log_disp"+num2str(i)), disable=1
		CheckBox $("record_disp"+num2str(i)), disable=1
		CheckBox $("plot_disp"+num2str(i)), disable=1
		
		if(i < number_of_measurements)
			SetVariable $("ctr_Name_"+num2str(i)), disable=0
			PopupMenu $("datatype"+num2str(i)), disable=0
			PopupMenu $("device"+num2str(i)), disable=0
			SetVariable $("calc_"+num2str(i)), disable=0
			CheckBox $("log_disp"+num2str(i)), disable=0

			CheckBox $("plot_disp"+num2str(i)), disable=0
			CheckBox $("record_disp"+num2str(i)), disable=0
		endif
	endfor
	
	GetWindow kwTopWin wsize
	movewindow V_left, V_top, V_right, V_top+40+20*number_of_measurements
end

Function set_Device(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
//	print "set_Device", ctrlName,popNum,popStr
	
	wave/T meas_device
	wave meas_device_ID
	
	wave device_family_ID
	wave/T device_meas_table
	
	
	variable meas_ID
	sscanf ctrlName, "device%d", meas_ID
	meas_device[meas_ID] = popStr
	
	meas_device_ID[meas_ID] = popNum - 1
	
	string meas_list
	meas_list = device_meas_table[device_family_ID[meas_device_ID[meas_ID]]][1]
	execute "PopupMenu datatype"+num2str(meas_ID)+", mode=1, value=\""+meas_list+"\""
End

Function set_MeasType(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

//	print "From set_MeasType:", ctrlName,popNum,popStr
	
	wave/T meas_type
	wave meas_type_ID
	
	variable meas_ID
	sscanf ctrlName, "datatype%d", meas_ID
	
	meas_type[meas_ID] = popStr
	meas_type_ID[meas_ID] = popNum - 1	
End

function set_meas_log(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	wave meas_log
	
	variable meas_ID
	sscanf CB_Struct.ctrlName, "log_disp%d", meas_ID
	
	meas_log[meas_ID] = CB_Struct.checked
end

function set_meas_plot(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	wave meas_plot
	
	variable meas_ID
	sscanf CB_Struct.ctrlName, "plot_disp%d", meas_ID
	
	meas_plot[meas_ID] = CB_Struct.checked
end

function set_meas_record(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	wave meas_record
	
	variable meas_ID
	sscanf CB_Struct.ctrlName, "record_disp%d", meas_ID
	
	meas_record[meas_ID] = CB_Struct.checked
end