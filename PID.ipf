#pragma rtGlobals=1		// Use modern global access method.

function TempSet(temp)
//PID controll (Omid's version) caution:works only below 150 mK

	variable   temp
	variable   t1,t2,Inew,Iend=0,i=0,jj=0,qq=0,k=0,s=0,d,dlast,Iex=0   
	variable   Imax    = 4                  //limit current: W heating power
	variable   R       = 4904               //resistor (heater + RC => sets heater voltage together with current) 
	                                        //resistor (heater + RC => heater=204.7Ohm, Lowpass resistance 4.7kOhm)
	variable   Tmax    = 200                //=? temp for Imax (depens on Pivc)
	variable   Taaa    = 1
 	variable   Ta      = 5                  //sampling rate of loop
   variable   secup   = Ta                 //when temperature is higher
   variable   secdwn  = 140                //when temperature is lower
	variable   Ks      = 0.013,Tu=30,Tg=0.5 //tg=570
	variable/G kp      = 0.1*  1.2*Tg/Tu/Ks	// Proportional coefficient	
	variable/G ki      = 0.4*  Kp/(2*Tu)    // integral coefficient
	variable/G Kd      = 7*  Kp*0.5*Tu      // differential coefficient
	variable/G Inow                         //in init
	variable/G next_wave
	
// K(p,i,d) determined from step response like here:
// http://www.rn-wissen.de/index.php/Regelungstechnik

	variable tstart=ticks,ti,secs
	string   wave1,wave2,wave3,wave4,wave5,wave6,wave7
	variable wnum=next_wave
	
	
	sprintf wave1,"%s%s_%d","Tmc","time",wnum;make/o/n=1000 $wave1=NaN;wave w1=$wave1
	setscale/i x 0,1,"",w1;showwaves(wave1);move_to_pos(1,12,1)

	sprintf wave2,"%s%s_%d","Iheater","time",wnum;make/o/n=1000 $wave2=NaN;wave w2=$wave2
	setscale/i x 0,1,"",w2;showwaves(wave2);move_to_pos(1,12,2)
	
	sprintf wave3,"%s%s_%d",".Proportional","time",wnum;make/o/n=1000 $wave3=NaN;wave w3=$wave3
	setscale/i x 0,1,"",w3;showwaves(wave3);move_to_pos(1,12,3)
	
	sprintf wave4,"%s%s_%d","Integral","time",wnum;make/o/n=1000 $wave4=NaN;wave w4=$wave4
	setscale/i x 0,1,"",w4;showwaves(wave4);move_to_pos(1,12,4)
	
	sprintf wave5,"%s%s_%d","Derivative","time",wnum;make/o/n=1000 $wave5=NaN;wave w5=$wave5
	setscale/i x 0,1,"",w5;showwaves(wave5);move_to_pos(1,12,5)
	
	sprintf wave6,"%s%s_%d","Temponline","time",wnum;make/o/n=10000 $wave6=NaN;wave w6=$wave6
	setscale/i x 0,1,"",w6;//showwaves(wave6);move_to_pos(1,12,6)
	
	sprintf wave7,"%s%s_%d","III","time",wnum;make/o/n=10000 $wave7=NaN;wave w7=$wave7
	setscale/i x 0,1,"",w7;//showwaves(wave7);move_to_pos(1,12,7)
	
	
 if(temp>Tmax)
			print "max. Temp: 200mK !"
 else		
	
    do
		t2  = read_Tmc_avg(3)//works only below 180 mK
		d   = temp-t2
		if(i==0)	// there's no 'dlast' in first round
		  dlast = d
		endif
		s+=d
		
		Inew = Inow + Kp*d +Ki*Ta*s + Kd*(d-dlast)/Ta	

			
	  if(Inew>Imax)
			Inew=Imax
		elseif(Inew<0)
			Inew=0
		endif
		
				if(abs(t2-temp)<0.02)	//mK precise controll
				k+=1
			  endif
			  if(k>100)
				Kd*=0.9	
			  endif
			
			SetWaveGenDC(8,(Inew/1000)*R)		// here the Visa for wavegen is 8			
			
			
			w1[i]=t2
			w2[i]=Inew/1000
			w3[i]=Kp*d/1000 
			w4[i]=Ki*Ta*s/1000
			w5[i]=Kd*(d-dlast)/Ta/1000
			w7[i]=Inew
						 
			dlast=d
			
			i+=1
			
			ti=ticks;secs=(ti-tstart)/(60.15*i)
			setscale/p x,0,secs,w1
			setscale/p x,0,secs,w2
			setscale/p x,0,secs,w3
			setscale/p x,0,secs,w4
			setscale/p x,0,secs,w5
			doupdate

		while(k<250)	//right temp for some minutes
		
	  Inow=Inew	
 endif
	//endsweep(tstart,ti)
	//save_data()
	//inc_nextwave()
end
//
//
//function TempSetTCMN(temp)
////PID controll (Omid's version) caution:works only below 150 mK
//
//	variable   temp
//	variable   t1,t2,Inew,Iend=0,i=0,jj=0,qq=0,k=0,s=0,d,dlast,Iex=0   
//	variable   Imax    = 4                  //limit current: W heating power
//	variable   R       = 4904               //resistor (heater + RC => sets heater voltage together with current) 
//	                                        //resistor (heater + RC => heater=204.7Ohm, Lowpass resistance 4.7kOhm)
//	variable   Tmax    = 200                //=? temp for Imax (depens on Pivc)
//	variable   Taaa    = 1
// 	variable   Ta      = 5                  //sampling rate of loop
//   variable   secup   = Ta                 //when temperature is higher
//   variable   secdwn  = 140                //when temperature is lower
//	variable   Ks      = 0.013,Tu=30,Tg=0.5 //tg=570
//	variable/G kp      = 0.1*  1.2*Tg/Tu/Ks	// Proportional coefficient	
//	variable/G ki      = 0.4*  Kp/(2*Tu)    // integral coefficient
//	variable/G Kd      = 7*  Kp*0.5*Tu      // differential coefficient
//	variable/G Inow                         //in init
//	variable/G next_wave
//	
//// K(p,i,d) determined from step response like here:
//// http://www.rn-wissen.de/index.php/Regelungstechnik
//
//	variable tstart=ticks,ti,secs
//	string   wave1,wave2,wave3,wave4,wave5,wave6,wave7
//	variable wnum=next_wave
//	
//	
//	sprintf wave1,"%s%s_%d","Tmc","time",wnum;make/o/n=1000 $wave1=NaN;wave w1=$wave1
//	setscale/i x 0,1,"",w1;showwaves(wave1);move_to_pos(1,12,1)
//
//	sprintf wave2,"%s%s_%d","Iheater","time",wnum;make/o/n=1000 $wave2=NaN;wave w2=$wave2
//	setscale/i x 0,1,"",w2;showwaves(wave2);move_to_pos(1,12,2)
//	
//	sprintf wave3,"%s%s_%d",".Proportional","time",wnum;make/o/n=1000 $wave3=NaN;wave w3=$wave3
//	setscale/i x 0,1,"",w3;showwaves(wave3);move_to_pos(1,12,3)
//	
//	sprintf wave4,"%s%s_%d","Integral","time",wnum;make/o/n=1000 $wave4=NaN;wave w4=$wave4
//	setscale/i x 0,1,"",w4;showwaves(wave4);move_to_pos(1,12,4)
//	
//	sprintf wave5,"%s%s_%d","Derivative","time",wnum;make/o/n=1000 $wave5=NaN;wave w5=$wave5
//	setscale/i x 0,1,"",w5;showwaves(wave5);move_to_pos(1,12,5)
//	
//	sprintf wave6,"%s%s_%d","Temponline","time",wnum;make/o/n=10000 $wave6=NaN;wave w6=$wave6
//	setscale/i x 0,1,"",w6;//showwaves(wave6);move_to_pos(1,12,6)
//	
//	sprintf wave7,"%s%s_%d","III","time",wnum;make/o/n=10000 $wave7=NaN;wave w7=$wave7
//	setscale/i x 0,1,"",w7;//showwaves(wave7);move_to_pos(1,12,7)
//	
//	
// if(temp>Tmax)
//			print "max. Temp: 200mK !"
// else		
//	
//    do
//		t2  = read_Tcmn_avg(5)//works only below 180 mK
//		d   = temp-t2
//		if(i==0)	// there's no 'dlast' in first round
//		  dlast = d
//		endif
//		s+=d
//		
//		Inew = Inow + Kp*d +Ki*Ta*s + Kd*(d-dlast)/Ta	
//
//			
//	  if(Inew>Imax)
//			Inew=Imax
//		elseif(Inew<0)
//			Inew=0
//		endif
//		
//				if(abs(t2-temp)<0.02)	//mK precise controll
//				k+=1
//			  endif
//			  if(k>100)
//				Kd*=0.9	
//			  endif
//			
//			SetWaveGenDC(8,(Inew/1000)*R)		// here the Visa for wavegen is 8			
//			
//			
//			w1[i]=t2
//			w2[i]=Inew/1000
//			w3[i]=Kp*d/1000 
//			w4[i]=Ki*Ta*s/1000
//			w5[i]=Kd*(d-dlast)/Ta/1000
//			w7[i]=Inew
//						 
//			dlast=d
//			
//			i+=1
//			
//			ti=ticks;secs=(ti-tstart)/(60.15*i)
//			setscale/p x,0,secs,w1
//			setscale/p x,0,secs,w2
//			setscale/p x,0,secs,w3
//			setscale/p x,0,secs,w4
//			setscale/p x,0,secs,w5
//			doupdate
//
//		while(k<250)	//right temp for some minutes
//		
//	  Inow=Inew	
// endif
//	//endsweep(tstart,ti)
//	//save_data()
//	//inc_nextwave()
//end
//
//
//function read_Tcmn_avg(twait)//caution:works only below 180 mK and above 5  mK
//	variable twait
//	variable t1=ticks,t2,tempp,j
//	variable counter=0,tsum=0,ii=1
//	make/o/n=1000 dummywave
//	make/o/n=100 dummywave2
//	do
//		do
//		dummywave[0]=0.004931/(abs(read_loY(3))/(2*pi*733.1*2e-06)-0.000461)+0.646
//		while(dummywave[0]>180 || dummywave[0]<10) 
//		do
//		dummywave[1]=0.004931/(abs(read_loY(3))/(2*pi*733.1*2e-06)-0.000461)+0.646
//		while(dummywave[1]>180 || dummywave[1]<10) 
//	while (abs(dummywave[0]-dummywave[1])>1)
//	
//	do
//	ii+=1
//		dummywave[ii]=0.004931/(abs(read_loY(3))/(2*pi*733.1*2e-06)-0.000461)+0.646
//		if(abs(dummywave[ii]-dummywave[ii-1])<1) 
//		tempp=dummywave[ii]
//    	counter+=1
//		tsum+=tempp
//		endif
//	t2=ticks
//	while((t2-t1)/60.15<twait)
//	tsum/=counter
//	return tsum
//end
//
//
//
////
function read_Tmc_avg(twait)//caution:works only below 180 mK and above 5  mK
	variable twait
	variable t1=ticks,t2,tempp,j
	variable counter=0,tsum=0,ii=1
	make/o/n=1000 dummywave
	make/o/n=100 dummywave2
	do
		do
		dummywave[0]=read_tmc(4)
		while(dummywave[0]>180 || dummywave[0]<10) 
		do
		dummywave[1]=read_tmc(4)
		while(dummywave[1]>180 || dummywave[1]<10) 
	while (abs(dummywave[0]-dummywave[1])>1)
	
	do
	ii+=1
		dummywave[ii]=read_tmc(4)
		if(abs(dummywave[ii]-dummywave[ii-1])<1) 
		tempp=dummywave[ii]
    	counter+=1
		tsum+=tempp
		endif
	t2=ticks
	while((t2-t1)/60.15<twait)
	tsum/=counter
	return tsum
end
//
//
//function dograph(wavenum)
//	variable wavenum
//	string id1="condvdc_"+num2str(wavenum)
//	display $id1;
//	string id2="tvdc_"+num2str(wavenum)
//	appendtograph/r $id2
//	modifygraph rgb($id2)=(0,0,0)
//	string id3="condtime_"+num2str(wavenum-1)
//	appendtograph/t $id3
//	modifygraph rgb($id3)=(0,34816,52224)
//	label left "g (e\S2\M/h)"
//	label top "Time (s)"
//	label right "T\BMC\M (mK)"
//	label bottom "V\BDC\M (mV)"
//	modifygraph fsize=7
//	string labelstr="\\Z07\r\\s("+id1+") "+id1+"\r\\s("+id3+") "+id3+"\rV\\BDC\\M\\Z07=0.035mV\r\\s("+id2+") "+id2
//	Legend/C/N=text0/J/F=0/B=3/A=LB labelstr
//	duplicate/o $id2 pw;wavestats/q pw;setaxis right v_min-0.5,v_max+0.5
//end
//
//function calibb()
//	variable i
//	variable/G inow
//	for(i=20;i<=100;i+=5)
//    tempset(i);wait(120);do1d("time",0,1,500,0.75)
//    setval("c1",-5);wait(300);do1d("c1",-5,5,500,0.75);setval("c1",0);
//	endfor
//	inow=0
//	SetWaveGenDC(8,0)	
//	do1d("time",0,1,4*3600,0.75);
//end
//
//function calibb2()
//	variable i
//	variable Vltg=0.7
//	for(i=0;i<12;i+=1)
//    print Vltg 
//    SetWaveGenDC(8,Vltg)
//    do1d("time",0,1,2400,0.75)
//    do1d("time",0,1,2400/6,0.75)
//    setval("c1",-5);wait(300);do1d("c1",-5,5,500,0.75);setval("c1",0);
//    Vltg=Vltg+0.1
//	endfor
//	SetWaveGenDC(8,0)	
//	do1d("time",0,1,4*3600,0.75);
//end
//
//
//
//function setcolor(num_color)
//	variable num_color
//	string trl=tracenamelist("",";",1), item
//	variable items=itemsinlist(trl), i
//	variable start=0
//	variable factor_ink=1
//	if(num_color==1)	
//		factor_ink=1/103*200;colortab2wave Geo
//	elseif(num_color==2)
//		factor_ink=1/103*450;colortab2wave SpectrumBlack
//	elseif(num_color==3)
//		factor_ink=1/103*310;colortab2wave ColdWarm
//	elseif(num_color==4)
//		factor_ink=1/103*240;colortab2wave Terrain256
//	elseif(num_color==5)
//		factor_ink=1/103*240;colortab2wave Grays256
//	elseif(num_color==6)
//		factor_ink=1/103*240;colortab2wave Copper
//	elseif(num_color==7)
//		factor_ink=1/103*90;colortab2wave Rainbow
//	elseif(num_color!=0)
//		abort "ABORT: no valid num-color, options are num_color{0,1,...,6}"
//	endif
//	if(num_color!=0)
//		variable ink=factor_ink*103/(items-1)
//		wave/i/u M_colors
//		for(i=0;i<items;i+=1)
//			item=stringfromlist(i,trl)
//			ModifyGraph rgb($item)=(M_colors[start+i*ink][0],M_colors[start+i*ink][1],M_colors[start+i*ink][2])
//		endfor
//	endif
//	killwaves/z M_colors
//end
//
//
//
//function HScurrFinder()
//   variable i
//	variable curr=770
//	for(i=0;i<25;i+=1)
//	setK2400Current(7,curr*1e+06)
//	do1d("time",0,1,60,0.7)
//	doupdate
//	curr+=5
//	endfor
//   do1d("time",0,1,200,0.7)
//end
//
//
//
//
//function TempSetCBT(temp,temp2)
////PID controll (Omid's version) caution:works only below 150 mK
//
//	variable   temp,temp2
//	variable   t1,t2,Inew,Iend=0,i=0,jj=0,qq=0,k=0,s=0,d,dlast,Iex=0   
//	variable   Imax    = 4                  //limit current: W heating power
//	variable   R       = 4904               //resistor (heater + RC => sets heater voltage together with current) 
//	                                        //resistor (heater + RC => heater=204.7Ohm, Lowpass resistance 4.7kOhm)
//	variable   Tmax    = 200                //=? temp for Imax (depens on Pivc)
//	variable   Taaa    = 1
// 	variable   Ta      = 5                  //sampling rate of loop
//   variable   secup   = Ta                 //when temperature is higher
//   variable   secdwn  = 140                //when temperature is lower
//	variable   Ks      = 0.013,Tu=30,Tg=0.5 //tg=570
//	variable/G kp      = 0.1*  1.2*Tg/Tu/Ks	// Proportional coefficient	
//	variable/G ki      = 0.4*  Kp/(2*Tu)    // integral coefficient
//	variable/G Kd      = 5*  Kp*0.5*Tu      // differential coefficient
//	variable/G Inow                         //in init
//	variable/G next_wave
//	variable check=0
//	
//// K(p,i,d) determined from step response like here:
//// http://www.rn-wissen.de/index.php/Regelungstechnik
//
//	variable tstart=ticks,ti,secs
//	string   wave1,wave2,wave3,wave4,wave5,wave6,wave7,wave8,wave9,wave10
//	variable wnum=next_wave
//	
//	
//	
//	sprintf wave1,"%s%s_%d","Tmc","time",wnum;make/o/n=1000 $wave1=NaN;wave w1=$wave1
//	setscale/i x 0,1,"",w1;showwaves(wave1);move_to_pos(1,12,1)
//
//	sprintf wave2,"%s%s_%d","Iheater","time",wnum;make/o/n=1000 $wave2=NaN;wave w2=$wave2
//	setscale/i x 0,1,"",w2;showwaves(wave2);move_to_pos(1,12,2)
//	
//	sprintf wave3,"%s%s_%d",".Proportional","time",wnum;make/o/n=1000 $wave3=NaN;wave w3=$wave3
//	setscale/i x 0,1,"",w3;showwaves(wave3);move_to_pos(1,12,3)
//	
//	sprintf wave4,"%s%s_%d","Integral","time",wnum;make/o/n=1000 $wave4=NaN;wave w4=$wave4
//	setscale/i x 0,1,"",w4;showwaves(wave4);move_to_pos(1,12,4)
//	
//	sprintf wave5,"%s%s_%d","Derivative","time",wnum;make/o/n=1000 $wave5=NaN;wave w5=$wave5
//	setscale/i x 0,1,"",w5;showwaves(wave5);move_to_pos(1,12,5)
//	
//	sprintf wave6,"%s%s_%d","Temponline","time",wnum;make/o/n=10000 $wave6=NaN;wave w6=$wave6
//	setscale/i x 0,1,"",w6;
//	
//	sprintf wave7,"%s%s_%d","III","time",wnum;make/o/n=10000 $wave7=NaN;wave w7=$wave7
//	setscale/i x 0,1,"",w7;
//	
//	sprintf wave8,"%s%s_%d","CBTdipCond","time",wnum;make/o/n=1000 $wave8=NaN;wave w8=$wave8
//	setscale/i x 0,1,"",w8;showwaves(wave8);move_to_pos(1,12,6)
//	
//	sprintf wave9,"%s%s_%d","Tcmn","time",wnum;make/o/n=1000 $wave9=NaN;wave w9=$wave9
//	setscale/i x 0,1,"",w9;showwaves(wave9);move_to_pos(1,12,7)
//	
//	sprintf wave10,"%s%s_%d","Lcmn3","time",wnum;make/o/n=1000 $wave10=NaN;wave w10=$wave10
//	setscale/i x 0,1,"",w10;showwaves(wave10);move_to_pos(1,12,8)
//	
// if(temp>Tmax)
//			print "max. Temp: 150mK !"
// else		
//	
//    do
//		t2  = read_Tmc_avg(3)//works only below 180 mK
//		d   = temp-t2
//		if(i==0)	// there's no 'dlast' in first round
//		  dlast = d
//		endif
//		s+=d
//		
//		Inew = Inow + Kp*d +Ki*Ta*s + Kd*(d-dlast)/Ta	
//
//			
//	  if(Inew>Imax)
//			Inew=Imax
//		elseif(Inew<0)
//			Inew=0
//		endif
//		
//				if(abs(t2-temp)<0.02)	//mK precise controll
//				k+=1
//			  endif
//			  if(k>100)
//				Kd*=0.9	
//			  endif
//
//			SetWaveGenDC(8,(Inew/1000)*R)		// here the Visa for wavegen is 8			
//			
//			
//			w1[i] =t2
//			w2[i] =Inew/1000
//			w3[i] =Kp*d/1000 
//			w4[i] =Ki*Ta*s/1000
//			w5[i] =Kd*(d-dlast)/Ta/1000
//			w7[i] =Inew
//			w8[i] =(1/(1/(read_loX(1)/(1e+08)/(4e-06))-8200))/(7.74809e-05)
//			w9[i] =0.004931/(abs(read_loY(3))/(2*pi*733.1*2e-06)-0.000461)+0.646
//			w10[i]=0		 
//			dlast=d
//			
//			i+=1
//			
//			ti=ticks;secs=(ti-tstart)/(60.15*i)
//			setscale/p x,0,secs,w1
//			setscale/p x,0,secs,w2
//			setscale/p x,0,secs,w3
//			setscale/p x,0,secs,w4
//			setscale/p x,0,secs,w5
//			setscale/p x,0,secs,w8
//			setscale/p x,0,secs,w9
//			setscale/p x,0,secs,w10
//			doupdate
//
//		while(i<500)	//right temp for some minutes	
//		Inow=Inew
//		Kd=7*Kp*0.5*Tu
//		
//		
//		s=0
//		i=0
//		k=0
//		do
//			t2  = read_Tmc_avg(3)//works only below 180 mK
//			d   = temp2-t2
//			if(i==0)	// there's no 'dlast' in first round
//			  dlast = d
//			endif
//			s+=d
//			if(-d>1.5)
//				s=0
//			endif
//			
//			
//			Inew = Inow + Kp*d +Ki*Ta*s + Kd*(d-dlast)/Ta	
//
//			
//		  if(Inew>Imax)
//				Inew=Imax
//			elseif(Inew<0)
//				Inew=0
//			endif
//		
//			if(abs(t2-temp2)<0.02)	//mK precise controll
//				k+=1
//			endif
//			if(k>100)
//				Kd*=0.9	
//			endif
//
//			SetWaveGenDC(8,(Inew/1000)*R)		// here the Visa for wavegen is 8			
//			
//			
//			w1[i+500] =t2
//			w2[i+500] =Inew/1000
//			w3[i+500] =Kp*d/1000 
//			w4[i+500] =Ki*Ta*s/1000
//			w5[i+500] =Kd*(d-dlast)/Ta/1000
//			w7[i+500] =Inew
//			w8[i+500] =(1/(1/(read_loX(1)/(1e+08)/(4e-06))-8200))/(7.74809e-05)
//			w9[i+500] =0.004931/(abs(read_loY(3))/(2*pi*733.1*2e-06)-0.000461)+0.646
//			w10[i+500]=0
//						 
//			dlast=d
//			
//			i+=1
//			
//			ti=ticks;secs=(ti-tstart)/(60.15*(i+500))
//			setscale/p x,0,secs,w1
//			setscale/p x,0,secs,w2
//			setscale/p x,0,secs,w3
//			setscale/p x,0,secs,w4
//			setscale/p x,0,secs,w5
//			setscale/p x,0,secs,w8
//			setscale/p x,0,secs,w9
//			setscale/p x,0,secs,w10
//			doupdate
//
//		while(i<500)	//right temp for some minutes
//		
//	
//	  Inow=Inew	
// endif
//	endsweep(tstart,ti)
//	inc_nextwave()
//end
//
//
//function oscmc()
// variable curr=-600
// variable i
//  	 for(i=0;i<13;i+=1)
//  	 print curr
//  	setK2400Current(7,curr*1e+06)
//   	TempSetCBT(70,55)
//   	curr=curr+50
//   	setK2400Current(7,curr*1e+06)
//   	wait(5)
//   	curr=curr+50
//   	wait(5)
// 	 endfor
// //setK2400Current(7,800*1e+06)
// SetWaveGenDC(8,0)
// do1d("time",0,1,4*3600,0.7)	
//end
//
//
//
//
//
////function dcollector()
////	variable i,cur=-1050
////	string baseid="cbtdipcondtime_",id
////	variable istart=293
////	variable istop=314
////	make/o/n=(22) GovG0mat
////	make/o/n=(22) currr
////	
////	for(i=istart;i<istop;i+=1)
////		id=baseid+num2str(i)
////		wavestats/q $id
////		GovG0mat[i-istart]=V_avg
////		currr[i-istart]=cur
////		cur+=100
////	endfor
////display GovG0mat vs currr
////end
//
//
//
//
//
//
//
//function dcollectorcbt()
//	variable i,cur=400
//	string baseid="cbtdipcondtime_",id
//	variable istart=317
//	variable istop=325
//	make/o/n=(9) GovG0mat
//	make/o/n=(9) currmat
//	
//	for(i=istart;i<=istop;i+=1)
//		id=baseid+num2str(i)
//		duplicate/o $id wavv1 
//		GovG0mat[i-istart]=(1/(1/(7.74809e-05*wavv1[560])-8.2e+03))/(7.74809e-05)
//		currmat[i-istart]=cur
//		cur-=100
//	endfor
//display GovG0mat vs currmat
//ModifyGraph mode=4
//ModifyGraph rgb=(0,0,0)
//ModifyGraph marker=19
//Label bottom "Current (mA)"
//Label left "G(Vb=0)/G0"
//end
//
//function dcollectorcbttemp()
//	variable i,cur=400
//	variable Ec=17
//	variable gt=0.3165
//	string baseid="cbtdipcondtime_",id
//	variable istart=317
//	variable istop=325
//	make/o/n=(9) tempmat
//	make/o/n=(9) currmat
//	
//	for(i=istart;i<=istop;i+=1)
//		id=baseid+num2str(i)
//		duplicate/o $id wavv1 
//		tempmat[i-istart]=Ec/((1-(((1/(1/(7.74809e-05*wavv1[560])-8.2e+03))/(7.74809e-05))/gt))*6)
//		currmat[i-istart]=cur
//		cur-=100
//	endfor
//display tempmat vs currmat
//ModifyGraph mode=4
//ModifyGraph rgb=(0,0,0)
//ModifyGraph marker=19
//Label bottom "Current (mA)"
//Label left "Tcbt (mK)"
//end
//
//
//
//
//
//
//
//
//
//function dcollectorlcmn3()
//	variable i,cur=400
//	string baseid="lcmn3time_",id
//	variable istart=317
//	variable istop=325
//	make/o/n=(9) resmat
//	make/o/n=(9) currmat
//	
//	for(i=istart;i<=istop;i+=1)
//		id=baseid+num2str(i)
//		duplicate/o $id wavv1 
//		resmat[i-istart]=wavv1
//		currmat[i-istart]=cur
//		cur-=100
//	endfor
//display resmat vs currmat
//ModifyGraph mode=4
//ModifyGraph rgb=(0,0,0)
//ModifyGraph marker=19
//Label bottom "Current (mA)"
//Label left "L-cmn3"
//end
//
//
//
//
//
//
//function dcollectorlcmn2()
//	variable i,cur=400
//	string baseid="lcmn2time_",id
//	variable istart=317
//	variable istop=325
//	make/o/n=(9) resmat
//	make/o/n=(9) currmat
//	
//	for(i=istart;i<=istop;i+=1)
//		id=baseid+num2str(i)
//		duplicate/o $id wavv1 
//		resmat[i-istart]=wavv1
//		currmat[i-istart]=cur
//		cur-=100
//	endfor
//display resmat vs currmat
//ModifyGraph mode=4
//ModifyGraph rgb=(0,0,0)
//ModifyGraph marker=19
//Label bottom "Current (mA)"
//Label left "L-cmn2"
//end
//
//
//
//
//
//
//
//
//
//
//
//
//
//function dispwaves()
//	variable i
//	string baseid="lcmn2time_",id
//	variable istart=317
//	variable istop=325
//	//display
//	for(i=istart;i<istop;i+=1)
//		id=baseid+num2str(i)
//		appendtograph $id
////		print id
//	endfor
//	setcolor(1)
//end
//
//
//function dispcbtwaves()
//	variable i
//	string baseid="cbtdipcondtime_314"
//	
//	duplicate/o $baseid wavv1 
//	duplicate/o $baseid cbtcond
//
//	for(i=0;i<1000;i+=1)
//		cbtcond[i]=(1/(1/(7.74809e-05*wavv1[i])-8.2e+03))/(7.74809e-05)
//	endfor
//	appendtograph/r cbtcond
//	Label right "G(Vb=0)/G0"
//	ModifyGraph rgb(cbtcond)=(1,12815,52428)
//	TextBox/C/N=text0/F=0/A=MC "Heat switch magnet current=1050 mA"
//	TextBox/C/N=text1/F=0/A=MC "demag field= 4T"
//	ModifyGraph width=283.465,height=198.425
//end
//
//
//
//
//function dispcbtwaves2(wnum)
//	variable wnum
//	variable i
//	string baseid="cbtdipcondtime_",id
//	string baseid2="cbtcond_"
//	baseid=baseid+num2str(wnum)
//	baseid2=baseid2+num2str(wnum)
//	duplicate/o $baseid wavv1 
//	
//	duplicate/o $baseid cbtcond
//
//	for(i=0;i<1000;i+=1)
//		cbtcond[i]=(1/(1/(7.74809e-05*wavv1[i])-8.2e+03))/(7.74809e-05)
//	endfor
//	duplicate/o cbtcond $baseid2  
//	appendtograph $baseid2 
//end
//
//function totplot()
//variable i
//variable startp=317
//variable endp=325
//display
//	for(i=startp;i<=endp;i+=1)
//	dispcbtwaves2(i)
//	endfor
//	setcolor(1)
//	Label left "G(Vb=0)/G0"
//   Label bottom "time (s)"
//end
//
//
//
//
//
//function cbttempwaves(wnum)
//   variable wnum
//	variable i
//	variable Ech=14.7
//	variable gt=0.3165
//	string baseid="GovG0_time_"
//	string baseid2="cbttemp_"
//	variable step
//	baseid=baseid+num2str(wnum)
//	baseid2=baseid2+num2str(wnum)
//	step=dimsize($baseid,0)
//	duplicate/o $baseid wavv1 
//	duplicate/o $baseid cbttemp
//
//	for(i=0;i<step;i+=1)
//		cbttemp[i]=Ech/((1-(((1/(1/(7.74809e-05*wavv1[i])-8.2e+03))/(7.74809e-05))/gt))*6)
//	endfor
//	duplicate/o cbttemp $baseid2
//	appendtograph $baseid2
//end
//
//
//
//
//
//function slopeextractor()
//variable i,sl1,sl2,sl3,sl4,sl5
//variable curr0=400
//variable stslope=506, enslope=636 //two matrix elements you want to calculate the slope
//variable startp=317
//variable endp=325
//variable steps=endp-startp+1
//string baseid="cbtdipcondtime_",id
//make/o/n=(steps) slope
//make/o/n=(steps) curr
//
//	for(i=0;i<steps;i+=1)
//	id=baseid+num2str(startp+i)
//	duplicate/o $id dummy
//	sl1=dummy[enslope]-dummy[stslope] 
//	sl2=dummy[enslope+1]-dummy[stslope+1]
//	sl3=dummy[enslope+2]-dummy[stslope+2]
//	sl4=dummy[enslope+3]-dummy[stslope+3]
//	sl5=dummy[enslope+4]-dummy[stslope+4]
//	slope[i]=abs((sl1+sl2+sl3+sl4+sl5)/5)
//// slope[i]=sl1
//	curr[i]=curr0
//	curr0-=100
//	endfor
//display slope vs curr
//end
