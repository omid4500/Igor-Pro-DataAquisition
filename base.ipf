#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function setval(idstr,value)
	string idstr 	
	variable value
	variable return_v = 1
	variable/G NumChan
	wave/T log_file
	
	if(!cmpstr(idstr[0],"c",2))
		variable channel
		sscanf idstr, "c%d", channel
		if(V_flag==1 && (value<50) && (value>-5001) && channel>0 && channel<NumChan)	// !!!! --- critical protection of the device --- !!!
			rampDAC(channel,value)
		else
			abort("Protection: Gate voltage too large, channel "+num2str(channel)+" not changed")
		endif	


	elseif(!cmpstr(idstr,"Vsd",2))
		if(abs(value)<16)																// !!!! --- critical protection of the device --- !!!
			rampDAC(8,value)
		else
			print "DC voltage out of range"
		endif
		
		
	elseif(!cmpstr(idstr,"time",2))
		//do nothing
	
	elseif(!cmpstr(idstr,"bz",2))
		if(abs(value)<9)																	// !!!! ---   critical for quenching magnet   --- !!!
		
			variable/G IPS_VISA_address
			if(IPS_VISA_address>0)
				setTargetField_IPS_VISA(IPS_VISA_address,value)
			
				log_file[0][0] = "bz"
				log_file[0][1] = num2str(value)
			else
				print "You have to run init_IPS(IPS_VISA_address) first"
			endif

			//TODO:	lockin_I[16][1] = num2str(value)
		else
			print "Bz is too large"
		endif
		
 // the commented commands might be used for ramping keithly using the function setval.you should commentize the following commands to use these commands. 		
 //       elseif(!cmpstr(idstr,"keithleyI",2))
 //           keithleyID = find_instr_id("KeithleyI")
 //           if(numtype(keithleyID)!=0)
 //                  abort "ERROR: no such device found"
 //           else
 //                  rampK2400current(keithleyID, value) //nA
 //           endif
 //       elseif(!cmpstr(idstr,"keithleyV",2))
 //           keithleyID = find_instr_id("KeithleyV")
 //           if(numtype(keithleyID)!=0)
 //               abort "ERROR: no such device found"
 //           else
 //               rampK2400Voltage(keithleyID, value) //mV
 //       endif
		
		
		
	elseif(!cmpstr(idstr,"keithleyI",2))
		//rampK2400current(idstr, value*1e-9)
	elseif(!cmpstr(idstr,"keithleyV",2))
		//rampK2400Voltage(idstr, value*1e-3)
	else
		abort "ERROR: couldn't resolve idstr"
		return_v = 0
	endif
	
	return return_v
end


function/T get_meas_name(meas_ID)
	variable meas_ID
	wave/T meas_name
	wave/T meas_type
	string res
	res = meas_name[meas_ID]+meas_type[meas_ID]
	return res
end

//-------------BASE-------------

function init()
	init_get_label()
	// if the panels are already created, close (kill) them.
	dowindow /k GPIB_Devices_panel
	dowindow /k Data_Types_panel
	dowindow /k Constant_and_log_panel
	
	init_GPIB_Devices_panel()
	init_Data_Types_panel()
	init_Constant_and_log_panel()

	execute "GPIB_Devices_panel()"
	execute "Data_Types_panel()"
	execute "Constant_and_log_panel()"
	execute "initDAC()"

	string/G exception_list=""
	
	exception_list += "all_labels;"																// Graphs labels
	exception_list += "DAC;DACDivider;DACLabel;DACLimit;DACOffset;DACRange;"	    	// DAC
	exception_list += "device_family;device_family_ID;device_meas_table;"			   // GPIB devices panel
	exception_list += "GPIB_addresses;GPIB_names;GPIB_instr_ID;"						   // GPIB devices panel
	exception_list += "meas_device;meas_device_ID;meas_log;meas_name;"				   // Data types panel
	exception_list += "meas_type;meas_type_ID;calc_eq;"									   // Data types panel
	exception_list += "constant_name;constant_value;constant_desc;"					   // Constants panel
	make/O/T/N=(30,2) log_file
	exception_list += "log_file;"																	// Log data
end
function wait(seconds)
	variable seconds
	variable now=stopMStimer(-2)
	do
	while((stopMStimer(-2)-now)/1e6 < seconds)
end
function set_nextwave(val)
	variable val
	
	variable/G next_wave
	next_wave = val
end
function get_nextwave()
	variable/G next_wave
	return next_wave
end
function inc_nextwave()
	variable/G next_wave
	next_wave+=1
end

function makecolorful([rev, nlines])	//nlines = # of lines share the same color
	variable rev, nlines
	variable num=0, index=0,colorindex
	string tracename
	string list=tracenamelist("",";",1)
	colortab2wave rainbow  // yellowhot
	wave M_colors
	variable n=dimsize(M_colors,0), group
	do
		tracename=stringfromlist(index, list)
		if(strlen(tracename)==0)
			break
		endif
		index+=1
	while(1)
	num=index-1
	if( !ParamIsDefault(nlines))
		group=index/nlines-1
	endif
	index=0
	do
		tracename=stringfromlist(index, list)
		if( ParamIsDefault(nlines))
			if( ParamIsDefault(rev))
				colorindex=round(n*index/num)
			else
				colorindex=round(n*(num-index)/num)
			endif
		else
			if( ParamIsDefault(rev))
				colorindex=round(n*floor(index/nlines)/group)
			else
				colorindex=round(n*(group-floor((index)/nlines))/group)
			endif
		endif
		ModifyGraph rgb($tracename)=(M_colors[colorindex][0],M_colors[colorindex][1],M_colors[colorindex][2])
		index+=1
	while(index<=num)
	legend
end


function endsweep(t1,t2)
	variable t1,t2
	
	printf "created waves #%d, finished at %s, elapsed time %6.3f min (%6.3f sec)\r",get_nextwave(),time(),(t2-t1)/(60.15*60), (t2-t1)/60.15
	variable/g trace_time=(t2-t1)/(60.15*60)
	saveexperiment
end

function get_data()
	wave/T calc_eq
	variable/G number_of_measurements
	make/O/N=(number_of_measurements) meas_data
	meas_data = nan
	
	duplicate/O meas_data, V	
	duplicate/O meas_data, M
	
	variable i
	for(i=0;i<number_of_measurements;i+=1)
		meas_data[i] = get_one_data(i)
	endfor
	
	V = meas_data
	
	variable/G V_tmp
	for(i=0;i<number_of_measurements;i+=1)
		execute "V_tmp="+calc_eq[i]
		meas_data[i] = V_tmp
		M = meas_data
	endfor
end

function get_one_data(i)
	variable i	
	wave GPIB_instr_ID
	wave meas_device_ID
	wave/T meas_type
	variable value_read
	string teststr
	
	if(cmpstr(meas_type[i],"-",2)==0)
		value_read = nan
	else
		FUNCREF read_prototype read = $("read_"+meas_type[i])
		value_read = read(GPIB_instr_ID[meas_device_ID[i]])
	endif
	return value_read
end


function killlast()
	variable/G kill_flag
	string/G meas_graphs
	string/G meas_waves
	
	string name, cmd, tmp
	if(kill_flag==1)
		variable i
		for(i=0;i<itemsinlist(meas_graphs,";");i+=1)
			name= stringfromlist(i, meas_graphs,";")
			//			print name
			cmd = "Dowindow/K "+name
			execute cmd
		endfor
		
				
		for(i=0; i<itemsinlist(meas_waves,";"); i +=1)
			name= stringfromlist(i,meas_waves,";")
			sprintf  cmd, "KillWaves %s", name
			execute cmd
		endfor
		
		
		kill_flag = 0
		meas_graphs = ""
		meas_waves = ""
	else
		print "too late to KillLast"
	endif
end

function post_proc(annotation)
	string     annotation
	variable/G next_wave
	//	add_legend()		// was useful for quantum dot experiments
	current_folder()
	save_data()
	current_remote_folder()
	save_remote_data()
	//	save_log()
	execute "data_Layout()"
	save_layout()
	hide_new_graphs()
	next_wave=next_wave+1
end

function add_legend()
	wave DAC
	string c1 = num2str(DAC[1])
	string c2 = num2str(DAC[2])
	string c3 = num2str(DAC[3])
	string c4 = num2str(DAC[4])
	string c5 = num2str(DAC[5])
	string c6 = num2str(DAC[6])
	string c7 = num2str(DAC[7])
end
function /S executeWinCmd(command)
	// run the shell command
	// if logFile is selected, put output there
	// otherwise, return output
	string command
	PathInfo home
	string dataPath = S_Path
	dataPath=ParseFilePath(5, dataPath, "\\", 0, 0)
	// open batch file to store command
	variable batRef
	string batchFile = "_execute_cmd.bat"
	string batchFull = datapath + batchFile
	Open/P=home batRef as batchFile	// overwrites previous batchfile
	//print "S_path = ", S_Path

	// setup log file paths
	string logFile = "_execute_cmd.log"
	string logFull = datapath + logFile

	// write command to batch file and close
	fprintf batRef,"%s > \"%s\"\r", command, logFull
	Close batRef
	//print batchFull
	// execute batch file with output directed to logFile
   //	String text
   //	sprintf text, "cmd.exe /C \"%s\"", batchFull
   ExecuteScriptText /Z /W=5.0 /B "\"" + batchFull + "\""


	string outputLine, result = ""
	variable logRef
	Open/P=home logRef as logFile
	do
		FReadLine logRef, outputLine
		if( strlen(outputLine) == 0 )
			break
		endif
		result += outputLine
	while( 1 )
	Close logRef
	//DeleteFile /P=data /Z=1 batchFile // delete batch file
	//DeleteFile /P=data /Z=1 logFile // delete batch file
	return result

end
function/S executeMacCmd(command)
	// http://www.igorexchange.com/node/938
	string command

	string cmd
	sprintf cmd, "do shell script \"%s\"", command
	ExecuteScriptText /UNQ /Z /W=5.0 cmd

	return S_value
end
function /S getHostName()
	// find the name of the computer Igor is running on
	string platform = igorinfo(2)
	string result, hostname, location

	strswitch(platform)
		case "Macintosh":
			result = executeMacCmd("hostname")
			splitstring /E="([a-zA-Z0-9\-]+).(.+)" result, hostname, location
			return TrimString(LowerStr(hostname))
		case "Windows":
			hostname = executeWinCmd("hostname")
			return TrimString(LowerStr(hostname))
		default:
			abort "What operating system are you running?! How?!"
	endswitch

end

function current_folder()
	variable new = DateTime
	pathinfo home
	string s_new_path = S_path + "automatic"
	NewPath /C/O/Q current_date, s_new_path
	
	s_new_path = S_path + "automatic:"+Secs2Date(new,-2)
	NewPath /C/O/Q current_date, s_new_path
end

function current_remote_folder()
	pathinfo home
	string remote_root = "Z:Measurement_Data"
	string measurement_folder_name = StringFromList(ItemsInList(S_Path, ":")-1,S_Path, ":")
	string current_machine_name = getHostName()
	string s_new_path = remote_root + ":" + current_machine_name + ":" + measurement_folder_name

	NewPath /C/O/Q remote, s_new_path
end

function save_data()
	string/G meas_waves
	variable i
	string tmp
	for(i=0;i<ItemsInList(meas_waves,";");i+=1)
		tmp = StringFromList(i,meas_waves,";")
		Save/C/P=current_date $tmp as tmp+".ibw"
	endfor
end

function save_remote_data()
	string/G meas_waves
	variable i
	string w_name, f_name
	w_name = StringFromList(0,meas_waves,";")
	f_name = "d" + StringFromList(2,w_name,"_") + "_"
	f_name += StringFromList(1,w_name,"_")
	variable hdf5_id = InitSaveFilesRemote(f_name, logs=collect_logs())
	// in case saving on the remote machine fails
	// we do not want interruptions in the procedures 
	try
		for(i=0;i<ItemsInList(meas_waves,";");i+=1)
			w_name = StringFromList(i,meas_waves,";")
			SaveSingleWaveRemote(hdf5_id, w_name)
		endfor
		HDF5CloseFile /A hdf5_id
	catch
		print "Saving data on the remote path failed."
	endtry
end

function/s collect_logs()
	nvar number_of_devices, number_of_measurements
	wave /t gpib_names, device_family
	wave GPIB_addresses, GPIB_instr_ID
	variable i
	string buffer = ""
	string/G comments
	if (strlen(comments) == 0)
		comments = ""
	endif
	
	buffer = addJSONkeyval(buffer, "comment", comments, addquotes=1)
	buffer = addJSONkeyval(buffer, "filenum", num2str(get_nextwave()))
	string axis_labels = ""
	axis_labels = addJSONkeyval(axis_labels, "x", "", addquotes=1)
	axis_labels = addJSONkeyval(axis_labels, "y", "", addquotes=1)
	buffer = addJSONkeyval(buffer, "axis_labels", axis_labels)
	buffer = addJSONkeyval(buffer, "time_completed", date() + " " + time(), addquotes=1)
	buffer = addJSONkeyval(buffer, "time_elapsed", "0")
	
	string devbuffer = ""
	string gpib = ""
	variable instrID
	for (i=1; i <= number_of_devices; i+=1)
		if (cmpstr(device_family[i], "-") != 0)
			FUNCREF log_prototype loggerfunc = $("log_"+device_family[i])
			instrID = GPIB_instr_ID[i]
			gpib = num2istr(getAddressGPIB(instrID))
			devbuffer = addJSONkeyval(devbuffer, device_family[i] + "_" + gpib, loggerfunc(instrID))
		endif
	endfor
	buffer = addJSONkeyval(buffer, "devices", devbuffer)
	return buffer
end
function save_log()
	wave DAC=$"DAC"
	wave DACDivider=$"DACDivider"

	wave/T log_file

	variable/g trace_time
	variable/G number_of_devices
	variable/G number_of_measurements
	variable/G number_of_constants
	
	variable log_size = 0
	log_size += 20 + dimsize(DACDivider,0) + dimsize(DAC,0)
	log_size += dimsize(log_file,0)
	log_size += number_of_devices
	log_size += number_of_measurements
	log_size += number_of_constants
	
	make/O/T/N=(log_size) log_w
	log_w = ""
	
	variable i,k=0
	string tmp

	log_w[k]="DAC:"										//-------------
	k+=1
	for(i=0;i<dimsize(DAC,0);i+=1)
		sprintf tmp, "c%g = %g", i, DAC[i]
		log_w[k+i] = tmp
	endfor
	k+=i+1

	log_w[k]="DAC Divider:"								//-------------
	k+=1
	for(i=0;i<dimsize(DACDivider,0);i+=1)
		sprintf tmp, "c%g = %g", i, DACDivider[i]
		log_w[k+i] = tmp
	endfor
	k+=i+1
	
	log_w[k]="GPIB panel:"								//-------------
	k+=1
	for(i=1;i<=number_of_devices;i+=1)
		tmp = get_log_from_waves(i,"GPIB_names;device_family;GPIB_addresses;GPIB_instr_ID;")
		log_w[k+i] = tmp
	endfor
	k+=i+1

	log_w[k]="Data types panel:"						//-------------
	k+=1
	for(i=0;i<number_of_measurements;i+=1)
		tmp = get_log_from_waves(i,"meas_name;meas_device;meas_type;calc_eq;meas_log;")
		log_w[k+i] = tmp
	endfor
	k+=i+1

	log_w[k]="Constants and log data panel:"		//-------------
	k+=1
	for(i=0;i<number_of_constants;i+=1)
		tmp = get_log_from_waves(i,"constant_name;constant_value;constant_desc;")
		log_w[k+i] = tmp
	endfor
	k+=i+1


	log_w[k]="Log wave:"									//-------------
	k+=1
	for(i=0;i<dimsize(log_file,0);i+=1)
		sprintf tmp, "%s : %s", log_file[i][0], log_file[i][1]
		if(cmpstr(" : ",tmp,2)==1)
			log_w[k+i] = tmp
		else
			log_w[k+i] = ""
		endif
	endfor
	k+=i+1

		
	save/G/M="\r\n"/P=current_date log_w as "log_for_"+num2str(get_nextwave())+".txt"
	
	killwaves log_w
end

function/T get_log_from_waves(line,waves)
	variable line
	string waves
	
	string out, w_name_tmp, info
	out = ""
	
	variable i
	for(i=0;i<itemsinlist(waves,";");i+=1)
		w_name_tmp = stringFromList(i,waves,";")
		info = waveinfo($(w_name_tmp),0)
		if(NumberByKey("NUMTYPE", info)==0)
			wave/T w_tmp_T = $(w_name_tmp)
			out += w_tmp_T[line]+" "
		else
			wave w_tmp_V = $(w_name_tmp)
			out += num2str(w_tmp_V[line])+" "
		endif
	endfor
	
	return out
end

//	exception_list += "meas_device;meas_device_ID;meas_log;meas_name;"				// Data types panel
//	exception_list += "meas_type;meas_type_ID;calc_eq;"									// Data types panel
//	
//	exception_list += "constant_name;constant_value;constant_desc;"					// Constants panel
	
	

Window data_Layout() : Layout
	string name="exp_layout_"+num2str(get_nextwave())	

	NewLayout/N=$name/W=(7.5,42.5,360,516.5) as name
	add_graphs()
	execute "Tile"
	
	//	SetWindow $name, hide = 1			// hide layout
EndMacro

function add_graphs()
	string/G meas_graphs
	variable i
	 
	for(i=0;i<ItemsInList(meas_graphs,";");i+=1)
		AppendLayoutObject graph $(StringFromList(i,meas_graphs,";"))
	endfor
end

function save_layout()
	SavePICT/C=2/EF=1/E=-8/P=current_date as "exp_layout_"+num2str(get_nextwave())+".pdf"
end

function hide_new_graphs()
	string/G meas_graphs
	variable i
	string tmp
	for(i=0;i<ItemsInList(meas_graphs,";");i+=1)
		tmp = StringFromList(i,meas_graphs,";")
		SetWindow $tmp, hide = 1
	endfor
end

function wait_abort(seconds, ShowSweepControl,killSweepControl)
	variable seconds,ShowSweepControl,killSweepControl
	string cmd="abortmeasurementwindow()"
	if(ShowSweepControl==1)
		execute cmd
	endif	
	variable now=stopMStimer(-2)
	do
		sc_checksweepstate()
	while((stopMStimer(-2)-now)/1e6 < seconds)
	if(killSweepControl==1)
		dowindow /k SweepControl
	endif
end


//--------------TO BE REMOVED-----------------

// HDF 5 file handling
function InitSaveFilesRemote(h5name, [logs])
	//// create/open HDF5 files
	string h5name, logs
	wave x_data, y_data
	if(paramisdefault(logs)) // save meta data
		logs=""
	endif
	make /o/t/n=1 logs_wave = logs
	// Open HDF5 file
	variable hdf5_id
	HDF5CreateFile /P=remote hdf5_id as h5name + ".h5"

	// save x and y arrays
	HDF5SaveData /IGOR=-1 /TRAN=1 /WRIT=1 x_data , hdf5_id, "x_array"
	if(dimsize($"y_array",0) > 0)
		// 2D array
		HDF5SaveData /IGOR=-1 /TRAN=1 /WRIT=1 y_data , hdf5_id, "y_array"
	endif

	// Create metadata
	variable meta_group_ID
	HDF5CreateGroup hdf5_id, "metadata", meta_group_ID
	make /FREE /T /N=1 logs_wave = logs
	
	// The category is called sweep_logs to be compatible with Folk lab.
	HDF5SaveData /A="sweep_logs" logs_wave, hdf5_id, "metadata" 
	
	HDF5CloseGroup /Z meta_group_id
	if (V_flag != 0)
		Print "HDF5CloseGroup Failed: ", "metadata"
	endif

	return hdf5_id
end

function SaveSingleWaveRemote(hdf5_id, wn)
	variable hdf5_id
	// wave with name 'g1x' as dataset named 'g1x' in hdf5
	string wn
	string trimmedwn = StringFromList(0,wn,"_")

	HDF5SaveData /IGOR=-1 /TRAN=1 /WRIT=1 /Z $wn , hdf5_id, trimmedwn
	if (V_flag != 0)
		Print "HDF5SaveData failed: ", wn
		return 0
	endif

end
function find_instr_id(DeviceName)
	string DeviceName
	nvar number_of_devices
	wave/T gpib_names
	wave gpib_instr_id
	variable i
	for(i=1;i<=number_of_devices;i+=1)
		if(stringmatch(gpib_names[i], DeviceName)==1)
			return gpib_instr_id[i]
		endif
	endfor
	print "no such device found"
end

