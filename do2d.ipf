#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function do2d(idstr1,start1,stop1,numdivs1,delay1,idstr2, start2,stop2,numdivs2,delay2)
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

	hide("lay")

	variable/G number_of_measurements
	string/G meas_graphs = ""
	string/G meas_waves = ""
	variable/G kill_flag = 0
	wave meas_log
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
	variable i
	for(i=0;i<number_of_measurements;i+=1)
		if(cmpstr(meas_type(i),"-",2)==1)
			m_name = meas_name[i]+meas_type[i]+"_"+idstr1+"_"+idstr2+"_"+num2str(get_nextwave())
		elseif(cmpstr(meas_type(i),"-",2)==0)
			m_name = meas_name[i]+"_"+idstr1+"_"+idstr2+"_"+num2str(get_nextwave())
		endif
		make/O/N=(numpts1,numpts2) $(m_name)=nan
		setscale/I x, start1, stop1, $(m_name)
		setscale/I y, start2, stop2, $(m_name)
		
		showwaves(m_name)
				
		meas_graphs+=WinName(0,1)+";"
		meas_waves+=m_name+";"
	
		move_to_pos(1,12,i+1)
	endfor
	
	kill_flag = 1
	
	setval(idstr1,w_value_x[0])
	setval(idstr2,w_value_y[0])
	wait(1)

	variable t1,t2,time_per_point
	t1 = ticks
	print "start: ", Secs2Date(DateTime,-2), time()
	
	variable j_x,j_y
	for(j_x=0;j_x<numpts1;j_x+=1)
		
		setval(idstr1,w_value_x[j_x])
		if(j_x>0)
			wait(delay1)
		endif
		
		for(j_y=0;j_y<numpts2;j_y+=1)
			
			setval(idstr2,w_value_y[j_y])
			wait(delay2)
						
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
	endfor
	
	t2=ticks
	endsweep(t1,t2)
	
	post_proc("")
	kill_flag = 0
	inc_nextwave()
end
