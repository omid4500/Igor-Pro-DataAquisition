#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
window abortmeasurementwindow() : Panel
	//Silent 1 // building window
	variable/g sc_abortsweepsave=0, sc_pause=0, sc_abortnosave=0
	NewPanel /W=(500,700,750,750) /N=SweepControl// window size
	ModifyPanel frameStyle=2
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	//Button pausesweep, pos={10,15},size={110,20},proc=pausesweep,title="Pause"
	Button stopsweepsave, pos={10,15},size={110,20},proc=stopsweep,title="Abort and Save"
	Button stopsweepnosave, pos={130,15},size={110,20},proc=stopsweep,title="Abort"
	DoUpdate /W=SweepControl /E=1
endmacro

function stopsweep(action) : Buttoncontrol
	string action
	nvar sc_abortsweepsave,sc_abortnosave
	print "Aborted. Action is", action

	strswitch(action)
		case "stopsweepsave":
			sc_abortsweepsave = 1
			break
		case "stopsweepnosave":
			sc_abortnosave = 1
			break
	endswitch
end

//function pausesweep(action) : Buttoncontrol
//	string action
//	nvar sc_pause, sc_abortsweep

//	Button pausesweep,proc=resumesweep,title="Resume"
//	sc_pause=1
//	print "Sweep paused by user"
//end

//function resumesweep(action) : Buttoncontrol
//	string action
//	nvar sc_pause

//	Button pausesweep,proc=pausesweep,title="Pause"
//	sc_pause = 0
//	print "Sweep resumed"
//end



function sc_checksweepstate()
	nvar /Z sc_abortsweepsave, sc_pause, sc_abortnosave

	if(NVAR_Exists(sc_abortsweepsave) && sc_abortsweepsave==1)
		// If the Abort button is pressed during the scan, save existing data and stop the scan.
		post_proc("The scan was aborted during execution.")
		dowindow /k SweepControl
		sc_abortsweepsave=0
		sc_abortnosave=0
		sc_pause=0
		abort "Measurement aborted by user. Data saved automatically."
	elseif(NVAR_Exists(sc_abortnosave) && sc_abortnosave==1)
		// Abort measurement without saving anything!
		dowindow /k SweepControl
		sc_abortnosave = 0
		sc_abortsweepsave = 0
		sc_pause=0
		abort "Measurement aborted by user. Data not saved automatically. Run \"SaveWaves()\" if needed"
//	elseif(NVAR_Exists(sc_pause) && sc_pause==1)
		// Pause sweep if button is pressed
//		do
//			if(sc_abortsweep)
//				post_proc("The scan was aborted during the execution.")
//				dowindow /k SweepControl
//				sc_abortsweep=0
//				sc_abortnosave=0
//				sc_pause=0
//				abort "Measurement aborted by user"
//			elseif(sc_abortnosave)
//				dowindow /k SweepControl
//				sc_abortsweep=0
//				sc_abortnosave=0
//				sc_pause=0
//				abort "Measurement aborted by user. Data NOT saved!"
//			endif
//		while(sc_pause)
	endif
end