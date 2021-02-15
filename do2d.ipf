#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function do2d(idstr1,start1,stop1,numdivs1,delay1,idstr2, start2,stop2,numdivs2,delay2, [comment, meander, cmd, cmd_fast])
	string idstr1			// id of outer loop
	variable start1		// outer loop starting value
	variable stop1		// ending value
	variable numdivs1		// number of points minus 1
	variable delay1		// seconds of delay between sweeps
	string idstr2			// id of inner loop
	variable start2		// inner loop starting value
	variable stop2		// ending value
	variable numdivs2		// number of points minus 1
	variable delay2		// seconds of delay between points
	string comment
	string cmd, cmd_fast
	variable meander		// if True, the fast scan will alternate between scanning up and down
	variable j, scan_direction // variables to control meandering scans
	string/g id0=idstr1
	string/g id1=idstr2
	
	nvar sc_j1
	sc_j1 = 0
	if (paramisdefault(comment))
		comment = ""
	endif
	if (paramisdefault(cmd))
		cmd = ""
	endif
	if (paramisdefault(cmd_fast))
		cmd_fast = ""
	endif
	if (paramisdefault(meander))
		meander = 0
	endif

	kill_layouts()
	hide("lay")

	variable/G number_of_measurements
	string/G meas_graphs = ""
	string/G meas_waves = ""
	variable/G kill_flag = 0
	wave meas_log, meas_plot, meas_record
	wave/T meas_name
	wave/T meas_type
	
	make/O/N=(number_of_measurements) meas_data
	meas_data = nan
		
	variable numpts1=numdivs1+1
	variable numpts2=numdivs2+1
	
	make/o/n=(numpts1) w_value_x
	w_value_x[]=start1+p*(stop1-start1)/numdivs1
	duplicate/o w_value_x x_data // Used for saving waves in h5 format remotely

	make/o/n=(numpts2) w_value_y
	w_value_y[]=start2+p*(stop2-start2)/numdivs2
	duplicate/o w_value_y y_data // Used for saving waves in h5 format remotely

	string m_name
	variable i, i_plotted = 0
	for(i=0;i<number_of_measurements;i+=1)
		if(cmpstr(meas_type(i),"-",2)==1)
			m_name = meas_name[i]+meas_type[i]+"_"+idstr1+"_"+idstr2+"_"+num2str(get_nextwave())
		elseif(cmpstr(meas_type(i),"-",2)==0)
			m_name = meas_name[i]+"_"+idstr1+"_"+idstr2+"_"+num2str(get_nextwave())
		endif
		make/O/N=(numpts1,numpts2) $(m_name)=nan
		setscale/I x, start1, stop1, $(m_name)
		setscale/I y, start2, stop2, $(m_name)
		
		if (meas_plot[i] == 1 && meas_record[i] == 1)
			showwaves(m_name)
				
			meas_graphs+=WinName(0,1)+";"
			move_to_pos(1,12,i_plotted+1)
			i_plotted += 1
		endif
		meas_waves+=m_name+";"
	endfor
	
	kill_flag = 1
	
	setval(idstr1,w_value_x[0])
	setval(idstr2,w_value_y[0])
	wait(1)

	variable t1,t2,time_per_point
	t1 = ticks
	print "start: ", Secs2Date(DateTime,-2), time()
	wait_abort(1,1,0)
	variable j_x,j_y
	for(j_x=0;j_x<numpts1;j_x+=1)
		setval(idstr1,w_value_x[j_x])
		if (cmpstr(idstr1, "time", 0)==0)
			x_data[j_x] = datetime - Date2Secs(-1,-1,-1) - Date2Secs(1970,1,1)  // UNIX timestamp in UTC
		endif
		wait_abort(delay1,0,0)
		if (meander==1 && mod(j_x,2)==1) // reverse the scan direction if we're meandering
			scan_direction = -1
		else
			scan_direction = +1
		endif
		if (strlen(cmd) > 0)
			Execute /Z cmd
		endif

		for(j=0;j<numpts2;j+=1)
			if (scan_direction == -1)
				j_y = numpts2-j-1
			else
				j_y = j
			endif
			if (strlen(cmd_fast) > 0)
				Execute /Z cmd_fast
			endif			
			setval(idstr2,w_value_y[j_y])
			if (cmpstr(idstr2, "time", 0)==0)
				y_data[j_y] = datetime - Date2Secs(-1,-1,-1) - Date2Secs(1970,1,1)  // UNIX timestamp in UTC
			endif
			wait_abort(delay2,0,0)
						
			get_data()
	
			for(i=0;i<number_of_measurements;i+=1)
				if(cmpstr(meas_type(i),"-",2)==1)
					m_name = meas_name[i]+meas_type[i]+"_"+idstr1+"_"+idstr2+"_"+num2str(get_nextwave())
				elseif(cmpstr(meas_type(i),"-",2)==0)
					m_name = meas_name[i]+"_"+idstr1+"_"+idstr2+"_"+num2str(get_nextwave())
				endif
				wave tmp = $(m_name)
				tmp[j_x][j_y] = meas_data[i]
			
			endfor

			if(delay2<1)
				if(mod(j_y,10)==0)
					doupdate
				endif
			else
				doupdate
			endif
		endfor
		sc_j1 = j_x
	endfor
	
	t2=ticks
	endsweep(t1,t2)
	
	post_proc(comment)
	kill_flag = 0
//	inc_nextwave()  WHY WAS THIS HERE?! %^Y&@@%!@#$%
end
