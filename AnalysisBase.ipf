#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function init_get_label()
	make/T/O/N=(200,2) all_labels
	variable/G number_of_labels
	string/G exception_list=""	
	exception_list += "all_labels;"		// Graphs labels
	all_labels = ""
	variable i=0
	//----
	all_labels[i][0] = "R"
	all_labels[i][1] = "R\B%s\M (\uohm)"
	i+=1
	
	all_labels[i][0] = "G"
	all_labels[i][1] = "G\B%s\M (\\ue\\S2\\M/h)"
	i+=1
	
	all_labels[i][0] = "V"
	all_labels[i][1] = "V\B%s\M (\uV)"
	i+=1
	
	all_labels[i][0] = "I"
	all_labels[i][1] = "I\B%s\M (\uA)"
	i+=1

	all_labels[i][0] = "T"
	all_labels[i][1] = "T\B%s\M (\uK)"
	i+=1

	all_labels[i][0] = "c"
	all_labels[i][1] = "c\B%s\M (\umV)"
	i+=1

	all_labels[i][0] = "t"
	all_labels[i][1] = "t%s (\us)"
	i+=1
	
	all_labels[i][0] = "b"
	all_labels[i][1] = "B\B%s\M (\uT)"
	i+=1

	all_labels[i][0] = "P"
	all_labels[i][1] = "P\B%s\M (\umbar)"
	i+=1
	
	all_labels[i][0] = "L"
	all_labels[i][1] = "L\B%s\M (\uH)"
	i+=1
	//----
	number_of_labels = i
end

function/T get_label(s_name)
	string s_name
	variable/G number_of_labels
	wave/T all_labels
	string s_tmp
	variable i
	for(i=0;i<number_of_labels;i+=1)
		if(!cmpstr(s_name[0],all_labels[i][0],2))
			sprintf s_tmp, all_labels[i][1], s_name[1,strlen(s_name)-1]
		
			if(strlen(s_name)>=5)
				if(!cmpstr(s_name[strlen(s_name)-4,strlen(s_name)-1],"loPh",2))
					//					print "Phase ..."
					sprintf s_tmp, all_labels[i][1], s_name[1,strlen(s_name)-5]+"_Ph"
				endif
			endif
			
			if(strlen(s_name)>=4)
				if(!cmpstr(s_name[strlen(s_name)-3,strlen(s_name)-1],"loM",2))
					//					print "Magnitude ..."
					sprintf s_tmp, all_labels[i][1], s_name[1,strlen(s_name)-4]+"_M"
				endif
			endif
			
			return s_tmp
		endif
	endfor
	print "ERRPR in \"get_label()\" function in base.ipf: No Label found for:" + s_name
	return s_name
end

////////////////////////////Graph functions////////////////////////////////////////////

function labelgraph(labelstr,pos,fontsize)
	// labels the top graph putting labelstr above the data, without adding any extra border
	string labelstr	// text to insert
	variable pos		// position: 0=left, 1=center, 2=right, 3=off the right corner
	// Will remove anny label in the same place made by this function
	variable fontsize
	string fontstr
	if(fontsize==0)	// use this to mean default font size
		fontstr=""
	elseif(fontsize<10)	// there must be a better way to add a leading zero to a short number!
		sprintf fontstr,"\\Z0%d",fontsize
	elseif(fontsize<100)
		sprintf fontstr,"\\Z%d",fontsize
	else
		print "labelgraph failed - font too big"
		return 0
	endif
	string fullabel=fontstr+labelstr
	
	if(pos==0)
		textbox/c/n=lefttext/f=0/a=LB/x=0/y=100/b=3 fullabel
	elseif(pos==1)
		textbox/c/n=midtext/f=0/a=MB/x=0/y=100/b=3 fullabel
	elseif(pos==2)
		textbox/c/n=righttext/f=0/a=RB/x=0/y=100/b=3 fullabel
	elseif(pos==3)
		textbox/c/n=righttext/f=0/a=LB/x=100/y=100/b=3 fullabel
	else
		print "labelgraph failed - unrecognized position"
	endif
end

function showwaves(w_name)
	string W_name
	string label_x, label_y, label_color
	if(itemsInList(w_name,"_")<3)
		abort "wave has a wrong name to be shown with showwaves"
	endif	
	display
	if(wavedims($(w_name))==1)
		appendtograph $(w_name)
		label_x = get_label(stringfromlist(1,w_name,"_"))
		label_y = get_label(stringfromlist(0,w_name,"_"))
		label bottom label_x
		label left label_y
		modifyGraph tick=2,nticks=8,axThick=0.5,btLen=2,btThick=0.5,stLen=1
		modifyGraph stThick=0.5,ftThick=0.5,ttThick=0.5
		modifygraph gfsize=10,fsize=10	
	elseif(wavedims($(w_name))==2)
		appendimage $(w_name)
		label_x = get_label(stringfromlist(1,w_name,"_"))
		label_y = get_label(stringfromlist(2,w_name,"_"))
		label_color = get_label(stringfromlist(0,w_name,"_"))
		label bottom label_x
		label left label_y
		ModifyImage $(w_name) ctab= {*,*,YellowHot,0}
		ColorScale/C/N=text0/F=0/A=RC/E/X=0.00/Y=0.00 width=6, image=$(w_name), label_color
		ModifyGraph gFont="Arial", gfSize=10
	endif
	labelgraph(w_name,0,10)
	doupdate
end

function hide(objects)
	string objects //"g" will hide all graphs on the left screen, "l" all the layouts

	variable kill_line = 400
	
	string obj, name, cmd
	variable i
	
	if(cmpstr(objects,"g",2)==0)
		obj = WinList("*",";","WIN:1")
	elseif(cmpstr(objects,"l",2)==0)
		obj = WinList("*",";","WIN:4")
	else
		print "ERROR in the hide function, wrong argument"
		return 0
	endif
	
	for(i=0; i<itemsinlist(obj); i +=1)
		name = stringfromlist(i, obj)
		cmd = "GetWindow "+name+", wsize"
		execute cmd
		variable/G V_left
		if(V_left < kill_line)
			SetWindow $name, hide = 1
		endif
	endfor
end

function kill_graphs()
	variable/g next_wave
	variable numkill=next_wave-1
	string fulllist = WinList("*", ";","WIN:1")
	string name, cmd
	variable i	
	for(i=0; i<itemsinlist(fulllist); i +=1)
		name= stringfromlist(i, fulllist)
		killwindow $name
	endfor	
end

function kill_graphs_num(num)
	variable num
	string fulllist = WinList("*", ";","WIN:1")
	string name, cmd, wlist, str
	variable i,k,check=0
	for(i=0; i<itemsinlist(fulllist); i +=1)
		name= stringfromlist(i, fulllist)
		wlist= WaveList("*", ";", "WIN:"+name )
		
		for(k=0;k<itemsInList(wlist,"_");k+=1)
			str = stringfromlist(k,wlist,"_")
			if(numtype(str2num(str))==0)
				if(str2num(str)==num)
					check=1
					print "killed graph: "+name+"  ,containing waves: ",wlist
					killwindow $name
				endif
			endif
		endfor
	endfor	
	if(check==0)
		print "No graphs with this wavenumber found"
	endif	
end

function kill_layouts()
	string fulllist = WinList("*", ";","WIN:4")
	string name, cmd
	variable i
	for(i=0; i<itemsinlist(fulllist); i +=1)
		name= stringfromlist(i, fulllist)
		sprintf  cmd, "Dowindow/K %s", name
		execute cmd		
	endfor
end

Function KillAll()
	string fulllist = WinList("*", ";","WIN:5")
	string name, cmd
	variable i,j
	for(i=0; i<itemsinlist(fulllist); i +=1)
		name= stringfromlist(i, fulllist)
		sprintf  cmd, "Dowindow/K %s", name
		execute cmd		
	endfor
	fulllist = WaveList("*", ";","")
	string/G exception_list
	string item, exc_item, out_list, res
	out_list = ""	
	for(j=0;j<ItemsInList(fulllist,";");j+=1)
		item = stringFromList(j,fulllist,";")
		res = item + ";"
		for(i=0;i<ItemsInList(exception_list,";");i+=1)
			exc_item = stringFromList(i,exception_list,";")
			if(cmpstr(item, exc_item, 2)==0)
				res = ""
				break
			endif
		endfor
		out_list += res
	endfor
	fulllist = out_list
	
	for(i=0; i<itemsinlist(fulllist); i +=1)
		name= stringfromlist(i, fulllist)
		sprintf  cmd, "KillWaves %s", name
		execute cmd		
	endfor
end

function	move_to_pos(monitor, divider, pos)
	variable monitor //1,2
	variable divider //1,2,4,6,8,12
	variable pos//1..divider
	
	variable l_1, l_2, t_, r_1, r_2, b_
	variable v_size, h_size, l_, r_, v_delta, h_delta
	l_1 = 0.5
	l_2 = 51
	t_ = 2
	r_1 = 50
	r_2 = 100.5
	b_ = 28.5
	v_size = b_ - t_
	h_size = r_1 - l_1
	v_delta = 1
	h_delta = 0.4
	if(monitor==1)
		l_ = l_1
		r_ = r_1
	elseif(monitor == 2)
		l_ = l_2
		r_ = r_2
	endif
	variable w_v_size, w_h_size, n_v, n_h
	if(divider==1)
		n_v = 1
		n_h = 1
	elseif(divider==2)
		n_v = 2
		n_h = 1
	elseif(divider==4)
		n_v = 2
		n_h = 2
	elseif(divider==6)
		n_v = 2
		n_h = 3
	elseif(divider==12)
		n_v = 3
		n_h = 4
	endif
	w_v_size = v_size / n_v
	w_h_size = h_size	 / n_h
	variable  w_l, w_t, w_r, w_b
	variable v_n, h_n
	v_n = floor((pos-1)/ n_h)
	h_n = mod((pos-1), n_h)
	
	w_l = l_ + h_n * w_h_size
	w_t = t_ + v_n * w_v_size
	w_r = w_l + w_h_size - h_delta
	w_b = w_t + w_v_size - v_delta
	movewindow/M w_l, w_t, w_r, w_b
end


////////////////////////////////////////Linecut functions//////////////////////////////////

macro linecut()	// call with a 2d plot as the top window
	// Thanks to Alex Johnson for this awesome function
	silent 1
	string images=imagenamelist(winname(0,1),";")
	if(itemsinlist(images,";")==0)
		print "no images found in the top graph"
		return 0 
	endif

	if(strsearch(controlnamelist(winname(0,1)),"slice",0)!=-1)
		doslice("goawayslice")
	endif

	if(strsearch(controlnamelist(winname(0,1)),"profile",0)!=-1)
		return 0
	endif
	
	variable xcenter,ycenter
	getaxis/Q left
	if(V_flag==1)
		getaxis/Q right
	endif
	ycenter=(V_min+V_max)/2
	getaxis/Q bottom
	if(V_flag==1)
		getaxis/Q top
	endif
	xcenter=(V_min+V_max)/2
	make/o/n=6 hairx={-inf,0,inf,0,0,0},hairy={0,0,0,-inf,0,inf}
	appendtograph/C=(0,65535,0) hairy vs hairx
	ModifyGraph offset={xcenter,ycenter}, quickdrag=1
	
	Button goleft proc=doprofile,title="<-", pos={20,0}, size={20,14}
	Button goright proc=doprofile,title="->", pos={40,0}, size={20,14}
	Button goup proc=doprofile,title="up", pos={60,0}, size={20,14}
	Button godown proc=doprofile,title="dn", pos={80,0}, size={20,14}
	Button vertprofile proc=doprofile,title="V", pos={110,0}, size={20,14}
	Button horzprofile proc=doprofile,title="H", pos={130,0}, size={20,14}
	Button graphprofile proc=doprofile,title="Show Profile", pos={150,0}, size={100,14}
	Button goawayprofile proc=doprofile,title="Close", pos={250,0}, size={50,14}
	string/G profilenamestr="pw"
	string/G profilenamestr2=""
	string/G profilenamestr3=""
	SetVariable profilename noproc, title="Wave", value=profilenamestr, pos={302,0}, size={80,12}, labelback=(65535,65535,65535)
	SetVariable profilename2 noproc, title="Source 2", value=profilenamestr2, pos={382,0}, size={120,12}, labelback=(65535,65535,65535)
	SetVariable profilename3 noproc, title="Source 3", value=profilenamestr3, pos={502,0}, size={120,12}, labelback=(65535,65535,65535)
end

function graphcolors(graphname)
	string graphname	// make this "" to take the top graph
	
	make/o rwave={65280,65280,52224,32768,0,0,36864,0,32768}
	make/o gwave={0,43520,52224,65280,52224,15872,14592,0,32768}
	make/o bwave={0,0,0,0,52224,65280,65280,0,32768}
	variable imax=numpnts(rwave)
	string list
	
	if(strlen(graphname)>0)
		list=tracenamelist(graphname,";",1)
	else
		list=tracenamelist("",";",1)
	endif
	
	variable i=0
	
	do
		string trace=stringfromlist(i,list,";")
		if(strlen(trace)>0)
			if(strlen(graphname)>0)
				modifygraph /W=graphname rgb($trace)=(rwave[mod(i,imax)],gwave[mod(i,imax)],bwave[mod(i,imax)])
			else
				modifygraph rgb($trace)=(rwave[mod(i,imax)],gwave[mod(i,imax)],bwave[mod(i,imax)])
			endif
		endif
		i+=1
	while(strlen(trace)>0)
end


function doprofile(ctrlname): ButtonControl
	string ctrlname
	
	SVAR pstr = profilenamestr
	wave imagewave=imagenametowaveref(winname(0,1),stringfromlist(0,imagenamelist("",";")))
	variable xoffset,yoffset
	string offsetstr=stringbykey("offset(x)",TraceInfo("","hairy",0),"=",";")
	offsetstr=offsetstr[1,strlen(offsetstr)-2]
	xoffset=str2num(stringfromlist(0,offsetstr,","))
	yoffset=str2num(stringfromlist(1,offsetstr,","))

	SVAR wstr2=profilenamestr2
	variable flag2=0
	if(strlen(wstr2)>0)
		flag2=1
		string pstr2=pstr+"_2"
		wave imagewave2=$wstr2
	endif
	SVAR wstr3=profilenamestr3
	variable flag3=0
	if(strlen(wstr3)>0)
		flag3=1
		string pstr3=pstr+"_3"
		wave imagewave3=$wstr3
	endif

	string cmd
	variable xdelta=dimdelta(imagewave,0)
	variable ydelta=dimdelta(imagewave,1)
	if(stringmatch(ctrlname,"goleft"))
		xoffset=xoffset-abs(xdelta)
		sprintf cmd,"Modifygraph offset(hairy)={%5.8f,%5.8f}",xoffset,yoffset
		execute cmd
		ctrlname="vertprofile"
	elseif(stringmatch(ctrlname,"goright"))
		xoffset=xoffset+abs(xdelta)
		sprintf cmd,"Modifygraph offset(hairy)={%5.8f,%5.8f}",xoffset,yoffset
		execute cmd
		ctrlname="vertprofile"
	elseif(stringmatch(ctrlname,"goup"))
		yoffset=yoffset+abs(ydelta)
		sprintf cmd,"Modifygraph offset(hairy)={%5.8f,%5.8f}",xoffset,yoffset
		execute cmd
		ctrlname="horzprofile"
	elseif(stringmatch(ctrlname,"godown"))
		yoffset=yoffset-abs(ydelta)
		sprintf cmd,"Modifygraph offset(hairy)={%5.8f,%5.8f}",xoffset,yoffset
		execute cmd
		ctrlname="horzprofile"
	endif

	if(stringmatch(ctrlname,"vertprofile"))
		make/o/n=(dimsize(imagewave,1)) $pstr
		wave pw=$pstr
		pw[]=imagewave[(xoffset-dimoffset(imagewave,0))/xdelta][p]
		setscale/P x dimoffset(imagewave,1),ydelta,pw
		
		if(flag2)
			make/o/n=(dimsize(imagewave2,1)) $pstr2
			wave pw2=$pstr2
			pw2[]=imagewave2[(xoffset-dimoffset(imagewave2,0))/xdelta][p]
			setscale/P x dimoffset(imagewave2,1),ydelta,pw2
		endif
		if(flag3)
			make/o/n=(dimsize(imagewave3,1)) $pstr3
			wave pw3=$pstr3
			pw3[]=imagewave3[(xoffset-dimoffset(imagewave3,0))/xdelta][p]
			setscale/P x dimoffset(imagewave3,1),ydelta,pw3
		endif
	elseif(stringmatch(ctrlname,"horzprofile"))
		make/o/n=(dimsize(imagewave,0)) $pstr
		wave pw=$pstr
		pw[]=imagewave[p][(yoffset-dimoffset(imagewave,1))/ydelta]
		setscale/P x dimoffset(imagewave,0),xdelta,pw
		if(flag2)
			make/o/n=(dimsize(imagewave2,0)) $pstr2
			wave pw2=$pstr2
			pw2[]=imagewave2[p][(yoffset-dimoffset(imagewave2,1))/ydelta]
			setscale/P x dimoffset(imagewave2,0),xdelta,pw2
		endif
		if(flag3)
			make/o/n=(dimsize(imagewave3,0)) $pstr3
			wave pw3=$pstr3
			pw3[]=imagewave3[p][(yoffset-dimoffset(imagewave3,1))/ydelta]
			setscale/P x dimoffset(imagewave3,0),xdelta,pw3
		endif
	elseif(stringmatch(ctrlname,"graphprofile"))
		display $pstr
		if(flag2)
			appendtograph/R $pstr2
			graphcolors("")
		endif
		if(flag3)
			appendtograph/R $pstr3
			graphcolors("")
		endif
	else	// goaway
		killcontrol vertprofile
		killcontrol horzprofile
		killcontrol graphprofile
		killcontrol goawayprofile
		killcontrol profilename
		killcontrol profilename2
		killcontrol profilename3
		if(strsearch(tracenamelist(winname(0,1),";",1),"hairy",0)!=-1)
			removefromgraph $"hairy"
		endif
		killcontrol goleft
		killcontrol goright
		killcontrol goup
		killcontrol godown
	endif
end


////////////////////////////////////////////Load Waves functions/////////////////////////

// 1. add the sortcat to the "automatic" folder in the same folder as the current igor experiment
// 2a. call load_exp(123, plot_f = 1) to load and plot all the data with the measurement id = 123
// 2b. call load_exp(123) to only load the data without plitting it.

function load_exp(exp_num, [plot_f, print_f])
	variable exp_num, plot_f, print_f
	plot_f = paramisDefault(plot_f) ? 0 : plot_f
	print_f = paramisDefault(print_f) ? 0 : print_f
	
	load_wave("*"+num2str(exp_num), plot_f, print_f)
end

function load_wave(w_name, plot_f, print_f)
	string w_name
	variable plot_f, print_f
	
	pathinfo home
	string all_dirs = all_dirs_in_dir(S_path+"automatic:")
	string file_list = ""
	string file
	string wave_name
	
	variable i, j
	for(i=0;i<itemsinList(all_dirs);i+=1)
		newpath/O/Q tmp_path, stringfromList(i,all_dirs,";")
		
		file_list = indexedFile(tmp_path,-1,".ibw")
		
		for(j=0;j<itemsInList(file_list);j+=1)
			file = stringfromList(j,file_list,";")
		
			if(stringmatch(file, w_name+".ibw"))
				loadwave/H/Q/O/P=tmp_path file
				
				wave_name = replacestring(".ibw", file, "")
				if(print_f==1)
					print wave_name
				endif
							
				if(plot_f==1)
					showwaves(wave_name)
					move_to_pos(1,12,1)
				endif
			endif
		endfor
	endfor
end

function/T all_dirs_in_dir(s_dir)
	string s_dir
	string all_dirs = ""
	string tmp_dirs = ""
	string tmp_dir
	string tmp_sub_dirs
	variable i
	newpath/O/Q tmp_path, s_dir
	tmp_dirs = IndexedDir(tmp_path, -1, 1)
	all_dirs += tmp_dirs
	do
		tmp_sub_dirs = ""
		for(i=0;i<ItemsInList(tmp_dirs);i+=1)
			tmp_dir = StringFromList(i,tmp_dirs,";")
			tmp_sub_dirs += dirs_in_dir(tmp_dir)	
		endfor
		all_dirs += tmp_sub_dirs
		tmp_dirs = tmp_sub_dirs
	while(itemsinList(tmp_dirs,";")>0)
	return all_dirs
end

function/T dirs_in_dir(s_dir)
	string s_dir
	
	newpath/O/Q tmp_path, s_dir
	return IndexedDir(tmp_path,-1,1)
end

//////////////////////////////////////Color set//////////////////////////////////////////////

function setcolor(num_color)
	variable num_color
	string trl=tracenamelist("",";",1), item
	variable items=itemsinlist(trl), i
	variable start=0
	variable factor_ink=1
	if(num_color==1)	
		factor_ink=1/103*200;colortab2wave Geo
	elseif(num_color==2)
		factor_ink=1/103*450;colortab2wave SpectrumBlack
	elseif(num_color==3)
		factor_ink=1/103*310;colortab2wave ColdWarm
	elseif(num_color==4)
		factor_ink=1/103*240;colortab2wave Terrain256
	elseif(num_color==5)
		factor_ink=1/103*240;colortab2wave Grays256
	elseif(num_color==6)
		factor_ink=1/103*240;colortab2wave Copper
	elseif(num_color==7)
		factor_ink=1/103*90;colortab2wave Rainbow
	elseif(num_color!=0)
		abort "ABORT: no valid num-color, options are num_color{0,1,...,6}"
	endif
	if(num_color!=0)
		variable ink=factor_ink*103/(items-1)
		wave/i/u M_colors
		for(i=0;i<items;i+=1)
			item=stringfromlist(i,trl)
			ModifyGraph rgb($item)=(M_colors[start+i*ink][0],M_colors[start+i*ink][1],M_colors[start+i*ink][2])
		endfor
	endif
	killwaves/z M_colors
end

macro rainbow()
	execute "gr_rnb()"
endmacro

function gr_rnb()
	string name = WinName(0, 1)
	//print name
	if(stringmatch(name,"")==0)
		string ws = waves_1D_on_graph(name), tmp
		variable i, num = ItemsInList(ws, ";"), col_val
		for(i=0;i<num;i+=1)
			col_val = i/(num-1)
			tmp = StringFromList(i,ws,";")
			//			print  rnb(col_val,"R"),rnb(col_val,"G"),rnb(col_val,"B")
			ModifyGraph rgb($tmp)=(rnb(col_val,"R"),rnb(col_val,"G"),rnb(col_val,"B"))
		endfor
	else
		print "---ERROR--- function gr_rnb() no waves on the Graph"
	endif
end

function rnb(input, color) // input from 0 to 1, color R G B
	variable input
	string color
	variable R, G, B
	variable i_max = 1
	variable max_c = 65535
	variable tmp = input / i_max
	if(tmp < 0)
		print "---ERROR--- Wrong input to rnb() function"
		// input 0:max
		//read - yellow (max, 0, 0) (max, max, 0)
	elseif(tmp < 1/4)
		R = 1	
		G = 4*tmp
		B = 0
		// input max:2max
		//yellow to green (max, max, 0) (0, max, 0)
	elseif(tmp<1/2)
		R = 1 - 4*(tmp - 1/4)
		G = 1
		B = 0 
		//input 2max:3max
		//green to aqua (0, max, 0) (0, max, max)
	elseif(tmp<3/4)
		R = 0
		G = 1
		B = 4*(tmp - 1/2)
		//input 3max:4max
		//aqua to blue (0, max, max) (0, 0, max)
	elseif(tmp<=1)
		R = 0
		G = 1 - 4*(tmp - 3/4)
		B = 1
	else
		print "---ERROR--- Wrong input to rnb() function"
	endif
	R *= max_c
	G *= max_c
	B *= max_c	
	if(stringmatch(color, "R"))
		return R
	elseif(stringmatch(color, "G"))
		return G
	elseif(stringmatch(color, "B"))
		return B
	else	
		print "---ERROR--- Wrong input to rnb() function"
	endif
end

function/S waves_1D_on_graph(name)
	string name
	string rez="", tmp = ""
	string w_y
	variable i=0
	do
		w_y = WaveName(name, i, 1)
		tmp += w_y + ";"
		i += 1
	while(stringmatch(w_y,"")!=1)
	rez = simplify_str_list(tmp)
	return rez
end

function/S simplify_str_list(str_list)
	string str_list
	string tmp1, tmp2, rez
	variable i, j
	for(i=0;i<ItemsInList(str_list,";");i+=1)
		tmp1 = StringFromList(i,str_list,";")
		for(j=i+1;j<ItemsInList(str_list,";");j+=1)
			tmp2 = StringFromList(j,str_list,";")
			if(stringmatch(tmp1, tmp2))
				return simplify_str_list(cut_i(str_list,j))
			endif
		endfor
	endfor
	str_list = remove_str_list(str_list,";;")
	return str_list
end

function/S cut_i(str_list, i)
	string str_list
	variable i
	string rez = ""
	variable j
	for(j=0;j<ItemsInList(str_list,";");j+=1)
		if(j!=i)
			rez += StringFromList(j,str_list,";")+";"
		endif
	endfor
	return rez
end
function/S remove_str_list(str_list1, str_list2)		// remove items from str_list2 in str_list1
	string str_list1, str_list2
	string rez = "", str1, str2
	variable i, j, flag
	for(i=0;i<ItemsInList(str_list1,";");i+=1)
		str1 = StringFromList(i,str_list1,";")
		flag = 0
		for(j=0;j<ItemsInList(str_list2,";");j+=1)
			str2 = StringFromList(j,str_list2,";")
			if(stringmatch(str1, str2))
				flag = 1
			endif
		endfor
		if(flag == 0)
			rez += str1 + ";"
		endif
	endfor
	return rez
end