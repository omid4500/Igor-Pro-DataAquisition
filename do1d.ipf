#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function do1d(idstr,start,stop,numdivs,delay, [cmd, comment])
	string   idstr			// generalized 1D sweep - figures out from idstr what to sweep
	variable start			// starting value
	variable stop			// ending value
	variable numdivs		// number of points minus 1
	variable delay			// seconds of delay between points
	string   cmd				// the command to be executed in the main loop
	string   comment
	string/g id0=idstr
	//nvar     sc_j1
	string   command=""
	//sc_j1 = 0

	if (paramisdefault(cmd))
		cmd = ""
	endif
	if (paramisdefault(comment))
		comment = ""
	endif
	sprintf command ",do1d('%s', %d, %d, %d, %f, '%s')" idstr,start,stop,numdivs,delay, cmd
	comment += command
	
	kill_layouts()

	variable/G  number_of_measurements
	string/G    meas_graphs = ""
	string/G    meas_waves = ""
	variable/G  kill_flag = 0
	wave        meas_log
	wave/T      meas_name
	wave/T      meas_type
	wave        meas_plot
	
	variable /G measurement_start_time = DateTime
	variable /G sc_j1 = 0
	make/O/N=(number_of_measurements) meas_data
	meas_data = nan
	variable numpts=numdivs+1
	make /o/n=(0) y_data
	make/d/o/n=(numpts) x_data = 0
	if(cmpstr(idstr,"time",0)!=0)
		x_data[]=start+p*(stop-start)/numdivs
	endif
	
	string m_name
	variable i,i_plotted=0
	for(i=0;i<number_of_measurements;i+=1)
		if(cmpstr(meas_type(i),"-",2)==1)
			// Measurement field
			m_name = meas_name[i]+meas_type[i]+"_"+idstr+"_"+num2str(get_nextwave())
		elseif(cmpstr(meas_type(i),"-",2)==0)
			// Calculated field
			m_name = meas_name[i]+"_"+idstr+"_"+num2str(get_nextwave())
		endif
		make/O/N=(numpts) $(m_name)=nan
		setscale/I x, start, stop, $(m_name)

		if (meas_plot[i] == 1)
			showwaves(m_name)
			if(meas_log(i)==1)
				ModifyGraph log(left)=1
			endif
			meas_graphs += WinName(0,1) + ";"
			move_to_pos(1,12,i_plotted+1)
			i_plotted += 1
		endif

		meas_waves += m_name + ";"	
	endfor
	//	execute "tilewindows /o=1/a=(3,4)"
	kill_flag = 1
	setval(idstr,x_data[0])
	// new wait command showing abort button
	wait_abort(1,1,0)
	variable/G t1
	variable t2,time_per_point
	t1 = ticks
	print "start: ", Secs2Date(DateTime,-2), time()
	variable j
	for(j=0;j<numpts;j+=1)
		if (strlen(cmd) > 0)
			Execute /Z cmd
		endif
		setval(idstr,x_data[j])
		get_data()
	
		for(i=0;i<number_of_measurements;i+=1)
			if(cmpstr(meas_type(i),"-",2)==1)
				m_name = meas_name[i]+meas_type[i]+"_"+idstr+"_"+num2str(get_nextwave())
			elseif(cmpstr(meas_type(i),"-",2)==0)
				m_name = meas_name[i]+"_"+idstr+"_"+num2str(get_nextwave())
			endif
			wave tmp = $(m_name)
			tmp[j] = meas_data[i]
			
			if(cmpstr(idstr,"time",0)==0)
				t2=ticks
				time_per_point=(t2-t1)/(60*(j+1))
				x_data[j] = datetime - Date2Secs(-1,-1,-1) - Date2Secs(1970,1,1)  // UNIX timestamp in UTC
				setscale/p x,0,time_per_point,$(m_name)
			endif
		endfor
		if(mod(j,300)==0)
			saveexperiment
		endif

		if(delay<0.5)
			if(mod(j,10)==0)
				DoUpdate
				//ResumeUpdate
			endif
		else
			DoUpdate
			//ResumeUpdate
		endif
		sc_j1 = j // In case the scan is aborted, this variable is used to set the limits of the saved data.
		wait_abort(delay,0,0)		
	endfor
	
	t2=ticks
	endsweep(t1,t2)
	wait_abort(0,0,1)
	post_proc(comment)
	kill_flag = 0
end

function speed_test()
	variable i, t1, t2
	t1=ticks
	print "start: ", Secs2Date(DateTime,-2), time()
	
	for(i=0;i<=100;i+=1)
		//		readdmm(2)
		//		read_dc(2)
		//		get_one_data(0)

		//		Lockin_M_VISA(5)
		//		read_loM(5)
		//		get_one_data(0)
		
		get_data()	
	endfor
	t2=ticks
	endsweep(t1,t2)
end