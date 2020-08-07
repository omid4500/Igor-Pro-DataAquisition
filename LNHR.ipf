#pragma rtGlobals=1		// Use modern global access method.

//Written be Jeff Miller, Spring 2001
//This IPF contains the SetDAC() function to use the Jim MacArthur 20-bit D/A board
//InitDAC() should always be executed in each experiment before using the D/A
// DACRange AND DACOffset must be calibrated by the user!!!!!!!

//Modifications by Dominik "Max" Zumbuhl, 6/15/01
// made some finetuning adjustments :-)

//Updated for QCL by DMZ, 071130

//Updated for MNK-I by FS 080203
 

macro InitDAC()
	pauseupdate; silent 1

	variable/G NumChan=9				//# of available chanels 	(4 (or 8 if two boards present))
	variable/G ingot=1 					//ingot = 1 : ingot present and the used D/A board

	//	killwaves daclabel,dac,daclimit,dacdivider,dacoffset
	VDTOperationsPort2 COM1		//Designate COM1 as the DAC control port
	VDT2 baud=115200, stopbits=1, databits=8, parity=0, in=0, out=0, echo=1	//Set protocol
	vdtwrite2 "all on\n"
	if(!waveexists($"DAC"))
		make/O/D/N=(NumChan) $"DAC" 	//THE DAC wave
	endif
	if(!waveexists($"DACRange"))
		make/O/D/N=(NumChan) $"DACRange" 	//Define the full range of the DAC
	endif
	if(!waveexists($"DACOffset"))
		make/O/D/N=(NumChan) $"DACOffset" 	//Define the zero offset
	endif
	if(!waveexists($"DACDivider"))
		make/O/D/N=(NumChan) $"DACDivider" 	//Define the DACDivider value
		wave DACDivider = $"DACDivider"
		DACDivider = 1
		DACDivider[0] = nan
		DACDivider[8] = 522.193
	endif
	if(!waveexists($"DACLimit"))
		make/O/D/N=(NumChan) $"DACLimit" //Selfimposed voltagelimit to prevent blowing up your devices
	endif
	if(!waveexists($"DACLabel"))
		make/O/T/N=(NumChan) $"DACLabel"=""	// textwave for naming a channel
	endif

	variable/G INGOTRAMPSTEPC=20		// mV per step when ramping a coarse channel
	variable/G INGOTRAMPSTEPF=3		// mV per step when ramping a fine channel
	variable/G INGOTRAMPDELAY=.03		// seconds of delay per step
End

function rampDAC(chan,mv)	// ramps the total value of chan to mv, leaving the other channel untouched if linked
	variable chan,mv
	variable/G NumChan
	wave DAC=DAC
	wave dacdivider,dacoffset
	variable/G INGOTRAMPSTEPC,INGOTRAMPSTEPF,INGOTRAMPDELAY	// defined in InitDAC()
	if(chan<1 || chan>NumChan)
		printf "chan %d invalid\r",chan
		return 0 
	endif
	variable rampstep=NaN,mvstart=nan
	mvstart=DAC(chan)
	rampstep=INGOTRAMPSTEPF
	variable numsteps
	variable i=0
	
	//if(chan==8||chan==1)//||chan==2)
	if(chan==8)//||chan==2)
		if (abs(mvstart-mV)>0.1)
			numsteps=ceil(abs(252*(mv-mvstart)/rampstep))
			//numsteps=ceil(abs(100*(mv-mvstart)/rampstep))
			rampstep=(mv-mvstart)/numsteps
			make/o/n=(numsteps) chan_value//added by TML
			chan_value=(mvstart+p*rampstep)//added by TML
			i=0
			do
				i+=1
				wait(INGOTRAMPDELAY)
				//SetDAC(chan,(mvstart+i*rampstep))
				SetDAC(chan,chan_value[i])
			while(i<numsteps)
		endif
	else
		if (abs(mvstart-mV)>20)
			numsteps=ceil(abs((mv-mvstart)/rampstep))
			rampstep=(mv-mvstart)/numsteps
			i=0
			do
				i+=1
				wait(INGOTRAMPDELAY)
				SetDAC(chan,(mvstart+i*rampstep))
			while(i<numsteps)
		endif
	endif
	SetDAC(chan,mv)		// make sure there's no rounding error at the end
end

Function SetDAC(chan, mV) 	//set chan # chan to Voltage mV in millivolts 
	variable chan, mV			//(with 20-bit digitization error, of course)	
	variable/G NumChan
	wave DAC = DAC								// used to keep track of outputs 
	wave DACLimit = DACLimit			// user defined limits
	wave DACDivider = DACDivider					// used if divider is put on output of box
	wave DACOffset = DACOffset
	//	wave DACRange = DACRange			//Taras
	string/g cmdstr
	DAC[chan]=mv
	mV=mv/1000*dacdivider[chan]-DACOffset[chan]/1000
	string sumstring,s1,s2
	s1=num2str(chan)+" "
	sprintf s2,"%x" (mV+10)/20*16776960
	sumstring=s1+s2
	execute "vdtwrite2 "+"\""+sumstring+"\n\""
	cmdstr="\""+sumstring+"\n\""
End	

function CalDAC(chan)
	//uses dmm2
	variable chan
	wave dacdivider,daclimit,dacoffset
	dacdivider[chan]=1;dacoffset[chan]=0;daclimit[chan]=10000
	variable pts=10,ring=80,delay=0.01,delaylong=0.5,i,sumv,k
	
	variable/g dmm2
	string readname="read_"+num2str(get_nextwave())
	make/o/n=(pts) $readname=nan;wave read=$readname
	setscale/i x,-daclimit[chan]+daclimit[chan]/pts,0,read
	display $readname
	movewindow/I 0,0,4,2.5
	ModifyGraph mode($readname)=2,lsize($readname)=2,rgb($readname)=(0,0,52224)
	label left "\\Z07read voltage (mV)"
	label bottom "\\Z07DAC voltage (mV)"
	Legend/C/N=text0/F=0/A=LT/X=0.00/Y=0.00
	labelgraph("calibration of channel "+num2str(chan),0,7)
	setdac(chan,-daclimit[chan]+(daclimit[chan]/pts))
	for(i=0;i<pts;i+=1)
		sumv=0
		for(k=0;k<ring;k+=1)
			setdac(chan,-daclimit[chan]+(i+1)*(daclimit[chan]/pts)+daclimit[chan]/(2*pts)*(-1)^k*exp(-k/2))
			if(k>ring/2-1)			
				sumv+=readdmm(dmm2)
			endif	
		endfor
		read[i]=2*sumv/ring
		doupdate
	endfor
	CurveFit/q line  read /D 
	wave w_coef
	dacdivider[chan]=1/w_coef[1];daclimit[chan]=10000/dacdivider[chan];dacoffset[chan]=w_coef[0]*dacdivider[chan]
	TextBox/C/N=text0/F=0/A=RB "DACDivider = "+num2str(1/w_coef[1])+"\rDACOffset = "+num2str(w_coef[0]*dacdivider[chan])+" (mV)"
	Legend/C/N=text1/F=0/A=LT/X=0.00/Y=0.00
	setdac(chan,0)
end

		
function checkdac(id,start,stop,pts,delay)
	string id
	variable start,stop,pts,delay
	variable i,k,num=get_nextwave()
	variable/g dmm2
	string readname="read_"+num2str(num)
	string diffname="diff_"+num2str(num)
	make/o/n=(pts+1) $readname=nan,$diffname=nan
	wave read=$readname;wave diff=$diffname
	setval(id,start)
	setscale/i x,start,stop,read
	setscale/i x,start,stop,diff
	display diff
	appendtograph/r read
	if(abs(stop-start)>1000)
		movewindow/I 4.1,0,8.1,2.5
	else
		movewindow/I 8.2,0,12.2,2.5
	endif
	ModifyGraph mode($readname)=2,lsize($readname)=2,rgb($readname)=(0,0,52224)
	label bottom "\\Z07set voltage (mV)"
	label right "\\Z07read voltage (mV)"
	label left "\\Z07difference set/read voltage (mV)"
	labelgraph("calibration check of "+id,0,7)
	doupdate
	wait(2)
	for(i=0;i<pts+1;i+=1)
		setval(id,start+(stop-start)/pts*i)
		wait(delay)
		read[i]=(readdmm(dmm2)+readdmm(dmm2))/2
		diff[i]=start+(stop-start)/pts*i-read[i]
		doupdate
	endfor
	saveexperiment
end
