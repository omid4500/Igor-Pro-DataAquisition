#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function init_GPIB_Devices_panel()
	variable/G max_number_of_devices = 30
	variable/G number_of_devices = 0
	variable/G max_dev_types = 20
	Variable/G defaultRM_G = nan

	make/T/O/N=(max_number_of_devices) GPIB_names
	GPIB_names = ""

	make/O/N=(max_number_of_devices) GPIB_addresses
	GPIB_addresses = 0	

	make/O/N=(max_number_of_devices) GPIB_instr_ID
	GPIB_instr_ID = nan
	
	make/T/O/N=(max_number_of_devices) device_family
	device_family = ""
	
	make/O/N=(max_number_of_devices) device_family_ID
	device_family_ID = nan

	// edit GPIB_addresses,GPIB_names,device_family,device_family_ID	
	
	GPIB_names[0] = "-"
	GPIB_addresses[0] = 0
	device_family[0] = "-"
	device_family_ID[0] = 0
	
	init_device_meas_table()
end

Window GPIB_Devices_panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1230,40,1500,90) as "GPIB Devices"
	ModifyPanel cbRGB=(24576,24576,65300)
	SetVariable number_of_devices,pos={8,12},size={120,14},proc=set_number_of_devices,title="Number of devices:"
	SetVariable number_of_devices,limits={0,max_number_of_devices,1},value= number_of_devices
	Button init_button, pos={136,12}, size={40,14}, proc=init_devices, title="Connect"
	Button deinit_button, pos={180,12}, size={50,14}, proc=deinit_devices, title="Disconnect"
	
	set_number_of_devices("number_of_devices",number_of_devices,num2str(number_of_devices),"number_of_devices")
	
	create_GPIB_Devices_panel()
	update_GPIB_Devices_panel()
EndMacro

function create_GPIB_Devices_panel()
	variable/G max_number_of_devices
	
	wave/T GPIB_names
	wave/T device_family
	wave GPIB_addresses
	
	
	variable i
	for(i=1;i<max_number_of_devices+1;i+=1)
		SetVariable $("ctr_Name_"+num2str(i)), value=GPIB_names[i], title="Name: ", size={90,14}, pos={15,15+i*20}, disable=1, proc=name_was_set
		TitleBox $("dev_family_"+num2str(i)), size={60,14}, pos={115,15+i*20}, disable=1, frame=0
		SetVariable $("ctr_Address_"+num2str(i)), value=GPIB_addresses[i], size={60.00,14}, pos={160.00,15+i*20}, disable=1,title="GPIB",limits={0,31,1}
		TitleBox $("instr_ID_"+num2str(i)), size={60,14}, pos={230,15+i*20}, disable=1, frame=0
	endfor
end

function update_GPIB_Devices_panel()
	variable/G number_of_devices
	
	set_number_of_devices("",number_of_devices,"","")
end

function set_number_of_devices(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	//	print ctrlName,varNum,varStr,varName
	
	variable/G max_number_of_devices

	variable i
	for(i=1;i<max_number_of_devices+1;i+=1)
		SetVariable $("ctr_Name_"+num2str(i)), disable=1
		TitleBox $("dev_family_"+num2str(i)), disable=1
		SetVariable $("ctr_Address_"+num2str(i)), disable=1
		TitleBox $("instr_ID_"+num2str(i)), disable=1
		
		if(i<=varNum)
			SetVariable $("ctr_Name_"+num2str(i)), disable=0
			TitleBox $("dev_family_"+num2str(i)), disable=0
			SetVariable $("ctr_Address_"+num2str(i)), disable=0
			TitleBox $("instr_ID_"+num2str(i)), disable=0
		endif
	endfor
	
	GetWindow kwTopWin wsize
	movewindow V_left, V_top, V_right, V_top+40+20*varNum
end

Function name_was_set(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	wave/T device_family
	wave device_family_ID
	
	variable ID
	sscanf ctrlName, "ctr_Name_%d", ID
	
	device_family[ID] = get_device_family(varStr)
	device_family_ID[ID] = get_device_family_ID(varStr)
	TitleBox $("dev_family_"+num2str(ID)), title=get_device_family(varStr)
	//	print ctrlName,varNum,varStr,varName
	return 0
End

function init_devices(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if(B_Struct.eventCode==1)
		variable/G number_of_devices
		wave GPIB_instr_ID

		Button init_button, fColor=(65535,0,0)
		doupdate

		init_VISA_from_table()
		variable i
		for(i=1;i<number_of_devices+1;i+=1)
			TitleBox $("instr_ID_"+num2str(i)), title=num2str(GPIB_instr_ID(i))
		endfor
			
		Button init_button,fColor=(0,0,0)
	endif
end

function deinit_devices(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct

	if(B_Struct.eventCode==1)

		Button deinit_button, fColor=(65535,0,0)
		doupdate
	
		deinit_VISA_from_table()
		
		Button deinit_button,fColor=(0,0,0)
	endif
end

function init_VISA_from_table()
	wave/T GPIB_names
	wave GPIB_addresses
	
	duplicate/O GPIB_addresses, GPIB_instr_ID
	GPIB_instr_ID = nan
	
	variable/G number_of_devices
	string/G S_list_GPIB_devices
	
	string base_name
	base_name = "GPIB0::%d::INSTR"
	string device_name
	
	Variable dev_V
	Variable status
	Variable/G defaultRM_G
	Variable defaultRM
	
	if(numtype(defaultRM_G)==0)
		deinit_VISA_from_table()
	endif
	
	S_list_GPIB_devices = ""
		
	status = viOpenDefaultRM(defaultRM)
	defaultRM_G = defaultRM	

	Printf "Init DefaultRM=%d, %d\r", defaultRM, status

	variable i
	for(i=0;i<=number_of_devices;i+=1)
		if(!stringmatch(GPIB_names[i],"") && !stringmatch(GPIB_names[i],"-"))
			sprintf device_name, base_name, GPIB_addresses[i]
			//			print GPIB_names[i], device_name
	
			status = viOpen(defaultRM, device_name, 0, 0, dev_V)
			GPIB_instr_ID[i] = dev_V
			printf "%s \t %s \t %d %d\r", GPIB_names[i], device_name, dev_V, status
		endif
		S_list_GPIB_devices += GPIB_names[i]+";"
	endfor
end

Function deinit_VISA_from_table()

	Variable/G defaultRM_G
	string/G S_list_GPIB_devices
		
	variable status
	
	if(numtype(defaultRM_G)==0)
		status = viClose(defaultRM_G)
		Printf "Deinit DefaultRM=%d, %d\r", defaultRM_G, status
	else
		Print "All devices disconnected, VISA session is closed."
	endif
	defaultRM_G = NaN
	S_list_GPIB_devices = "-;"
end

function get_device_family_ID(device_name)
	string device_name
	
	variable/G dev_types	
	wave/T device_meas_table
	
	variable j
	for(j=0;j<dev_types;j+=1)
		if(string_starts(device_name,device_meas_table[j][0]))
			return j
		endif
	endfor
	return 0
end

function/T get_device_family(device_name)
	string device_name
	
	variable/G dev_types	
	wave/T device_meas_table
	
	variable j
	for(j=0;j<dev_types;j+=1)
		if(string_starts(device_name,device_meas_table[j][0]))
			return device_meas_table[j][0]
		endif
	endfor
	return "-"
end

function string_starts(in_s, sect_s)
	string in_s, sect_s
	
	if(cmpstr(in_s, sect_s)==0)
		return 1
	else
		string s1
		sscanf in_s, sect_s+"%s", s1
		return V_flag
	endif
	return 0
end

function init_device_meas_table()
	//	DMM: 		dc
	// Lock_in: loM
	//				loPh
	// AVS:     1K
	//				stil
	//				mc

	// to read value, use functions read_dc, read_lo_M, etc.

	variable/G max_dev_types
	variable/G dev_types
	string/G S_list_possible_devices

	variable i=0
	make/T/O/N=(max_dev_types,2) device_meas_table
	device_meas_table = ""
	
	device_meas_table[i][0] = "-"
	device_meas_table[i][1] = "-;"		
	i+=1

	device_meas_table[i][0] = "DMM"
	device_meas_table[i][1] = "-;dc;"
	i+=1
	
	device_meas_table[i][0] = "Lock_in"
	device_meas_table[i][1] = "-;loM;loPh;loX;loY"
	i+=1
	
	device_meas_table[i][0] = "AVS"
	device_meas_table[i][1] = "-;T1K;Tstil;Tmc;R1K;Rstil;Rmc;"
	i+=1

	device_meas_table[i][0] = "MaxiGauge"
	device_meas_table[i][1] = "-;PSTIL;PIVC;"
	i+=1

	device_meas_table[i][0] = "Keithley"
	device_meas_table[i][1] = "-;KeithleyV;KeithleyI;"
	i+=1

	device_meas_table[i][0] = "IPS"
	device_meas_table[i][1] = "-;IPSB;IPSI;IPSramprate;"
	i+=1
	
	device_meas_table[i][0] = "Lakeshore"
	device_meas_table[i][1] = "-;MCtemp;"
	i+=1


	dev_types = i
	
	S_list_possible_devices = ""
	variable j, ID
	for(j=0;j<=dev_types;j+=1)
		S_list_possible_devices += device_meas_table[j][0]+";"
	endfor
end
