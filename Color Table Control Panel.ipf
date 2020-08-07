#pragma rtGlobals=3		// Use modern global access method.
#pragma version=6.30		// Shipped with Igor 6.30
#pragma IndependentModule=WMColorTableControlPanel

#include <Resize Controls>

///////// some constants /////////
static constant Height = 490
static constant Width = 430

static constant cZInfoCIndexHighEqLow = 0x4          //// the color index wave will get set to point scaling if you try to use SetScale with highValue == lowValue
static constant cZInfoIsCIndex = 0x8 				//// set if an image uses a color index wave
static constant cZInfoGraphObjectMissing = 0x1   			//// set if the primary graph object is missing
static constant cZInfoCIndexWaveMissing = 0x2		//// set if the color index wave is missing   

Menu "Graph"
	"Color Table Control", /Q, createColorTableControlPanel()
End

//// execute WMColorTableControlPanel#createColorTableControlPanel()
//// createColorTableControlPanel will either create or move the current Color Table Control Panel, then update it to the current traces.  If there is 
////    any information on the traces in the package the panel controls will be updated
Function createColorTableControlPanel()

	DFREF colorTablePackageDFR = GetColorTableControlPanelDFR()
	InitColorTableControlPanel(colorTablePackageDFR)
	
	// Get the top graph
	DFREF colorTablePackageDFR = GetColorTableControlPanelDFR()
	String /G colorTablePackageDFR:topGraphName
	SVAR graphName = colorTablePackageDFR:topGraphName
	graphName = WinName(0,1)
	
	DoWindow/F ColorTableControlPanel
	if (V_flag == 0)		// i.e. the panel doesn't already exist
		PauseUpdate; Silent 1		// building window...
		
		NVAR panelHeight = colorTablePackageDFR:PanelHeight 
		NVAR panelWidth = colorTablePackageDFR:PanelWidth 
		Variable initialSliderHeight = panelHeight-270 
		NVAR xLocation = colorTablePackageDFR:xLocation 
		NVAR yLocation = colorTablePackageDFR:yLocation 
		
		NewPanel /K=1 /W=(xLocation, yLocation, xLocation+panelWidth, yLocation+panelHeight) /N=ColorTableControlPanel as "Color Table Control"
	
		Button helpButton,  win=ColorTableControlPanel,  pos={9, 7}, size={70, 20}, fsize=12, fstyle=1, title="Help", proc=Help
		SetVariable currGraph, win=ColorTableControlPanel,pos={100,9},size={panelWidth-110,20},title="Current Graph:", fsize=12, fstyle=1, frame=0, variable=colorTablePackageDFR:topGraphName
	
		PopupMenu selectTracePU, win=ColorTableControlPanel,pos={15,32},size={167,20},title="Target"
		PopupMenu selectTracePU, win=ColorTableControlPanel,fSize=12,mode=1,proc=SelectTraceProc			
		PopupMenu selectColorTablePU, win=ColorTableControlPanel,pos={15,57},size={270,20},title="Color Table",value=#"\"*COLORTABLEPOP*\"" 
		PopupMenu selectColorTablePU, win=ColorTableControlPanel,fSize=12,mode=0,proc=SelectColorTableProc
		TitleBox cIndexInUse, win=ColorTableControlPanel,pos={15,60},size={panelWidth-30,20},title="Color Index Wave", fsize=12, frame=0, disable=1
	
		TitleBox slidersTitle, win=ColorTableControlPanel, pos={10,118}, size={panelWidth-30, 16}, fsize=14, fstyle=1, title="Modify Color Table Range", frame=0, anchor=MC
			
		GroupBox statusGroup, win=ColorTableControlPanel, pos={5,80},size={panelWidth-10,36}		
		TitleBox statusText, win=ColorTableControlPanel, pos={15,82},size={panelWidth-30,30}, fsize=11, title=" ", frame=0		
		
		Slider highSliderSC, win=ColorTableControlPanel, pos={160,141},size={60,initialSliderHeight},fSize=10,limits={0,1,0.01},value=1, proc=SliderProc
		Slider lowSliderSC, win=ColorTableControlPanel, pos={20,141},size={60,initialSliderHeight},fSize=10,limits={0,1,0.01},value=0, proc=SliderProc
		SetVariable slidersHighSV, win=ColorTableControlPanel, pos={160, 149+initialSliderHeight}, size={120, 15}, fsize=12, title="Last", proc=setVarProc, bodyWidth=100, limits={-inf,inf,0}
		SetVariable slidersLowSV, win=ColorTableControlPanel, pos={20, 149+initialSliderHeight}, size={120, 15}, fsize=12, title="First", proc=setVarProc, bodyWidth=100, limits={-inf,inf,0}

		TitleBox slidersLimitsTitle, win=ColorTableControlPanel, pos={280,149+initialSliderHeight/2-115}, size={100, 20}, fsize=12, fstyle=1, title="Set Slider Limits", frame=0, anchor=MC
		GroupBox sliderGroup, win=ColorTableControlPanel, pos={270,149+initialSliderHeight/2-95}, size={120, 80}
		SetVariable maxSetSliderSV, win=ColorTableControlPanel, pos={280,149+initialSliderHeight/2-85}, size={100, 20}, fsize=12, title="Max", proc=sliderLimitsSetVarProc, limits={-inf,inf,0}
		SetVariable minSetSliderSV, win=ColorTableControlPanel, pos={283,149+initialSliderHeight/2-65}, size={97, 20}, fsize=12, title="Min", proc=sliderLimitsSetVarProc, limits={-inf,inf,0}
		Button autoCalcButton, win=ColorTableControlPanel, pos={280, 149+initialSliderHeight/2-45}, size={90, 20}, fsize=12, fstyle=1, title="Auto Calc", proc=sliderLimitsAutoCalc

		Checkbox holdAtEndsCheck, win=ColorTableControlPanel, pos={30, panelHeight-97}, size={70, 20}, fsize=12, fstyle=1; DelayUpdate
		Checkbox holdAtEndsCheck, win=ColorTableControlPanel, title="Hold Last-First Difference", variable=colorTablePackageDFR:WMHoldAtEnds

		Checkbox reverseTableCheck, win=ColorTableControlPanel, pos={panelWidth/2+30, panelHeight-97}, size={70, 20}, fsize=12, fstyle=1; DelayUpdate
		Checkbox reverseTableCheck, win=ColorTableControlPanel, title="Reverse Color Table", proc=reverseColorTableProc//, variable=colorTablePackageDFR:WMReverseColorTable

		GroupBox presetsGroup,pos={5,panelHeight-75},size={panelWidth-10,70}			
		TitleBox presetsLabel, win=ColorTableControlPanel, pos={15, panelHeight-70}, size={80, 15}, fsize=12, fstyle=1, title="Set and Load color table preset:", frame=0
		Button savePreset, win=ColorTableControlPanel, pos={15, panelHeight-47}, size={90, 20}, fsize=12, fstyle=1, title="Save Current", proc=SavePreset
		Button applyPreset, win=ColorTableControlPanel, pos={panelWidth/2-45, panelHeight-47}, size={90, 20}, fsize=12, fstyle=1, title="Apply", proc=ApplyPreset
		Button applyAllPreset, win=ColorTableControlPanel, pos={panelWidth-105, panelHeight-47}, size={90, 20}, fsize=12, fstyle=1, title="Apply to All", proc=ApplyPreset

		NVAR /Z highSliderPreset = colorTablePackageDFR:WMHighSliderPreset 
		NVAR /Z lowSliderPreset = colorTablePackageDFR:WMLowSliderPreset
		SVAR /Z colorTablePreset = colorTablePackageDFR:WMColorTablePreset 	
		if (!NVAR_exists(highSliderPreset) || !NVAR_exists(lowSliderPreset) || !SVAR_exists(colorTablePreset))
			InitColorTableControlPanel(colorTablePackageDFR)
			NVAR highSliderPreset = colorTablePackageDFR:WMHighSliderPreset 
			NVAR lowSliderPreset = colorTablePackageDFR:WMLowSliderPreset
			SVAR colorTablePreset = colorTablePackageDFR:WMColorTablePreset 
		endif
		SetVariable currentPresetSettings, win=ColorTableControlPanel, pos={20, panelHeight-25}, size={panelWidth-40, 20}, fsize=11, title="\f01Current Preset: "; DelayUpdate
		SetVariable currentPresetSettings, win=ColorTableControlPanel, frame=0, noedit=1
		String presetSettings
		if (numtype(highSliderPreset) != 2 && numtype(lowSliderPreset)!=2 && strlen(colorTablePreset)!=0 && CmpStr(colorTablePreset, "_none_"))
			sprintf presetSettings, "{%.2e, %.2e, %s}", lowSliderPreset, highSliderPreset, colorTablePreset
			SetVariable currentPresetSettings, win=ColorTableControlPanel, value=_STR:presetSettings
		else
			SetVariable currentPresetSettings, win=ColorTableControlPanel, value=_STR:"No Saved Preset"
		endif

		Button helpButton,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,@s!!#:B!!#?E!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
		Button helpButton,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		Button helpButton,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		SetVariable currGraph,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,F-!!#:r!!#BZ!!#<Pz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
		SetVariable currGraph,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		SetVariable currGraph,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		PopupMenu selectTracePU,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,B)!!#=c!!#A$!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
		PopupMenu selectTracePU,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		PopupMenu selectTracePU,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		PopupMenu selectColorTablePU,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,BA!!#>r!!#B@!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
		PopupMenu selectColorTablePU,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		PopupMenu selectColorTablePU,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		TitleBox cIndexInUse,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,B)!!#?)!!#C2J,hm.z!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
		TitleBox cIndexInUse,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		TitleBox cIndexInUse,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		TitleBox slidersTitle,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,Fg!!#@N!!#A:!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#`-A7TLfzz"
		TitleBox slidersTitle,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		TitleBox slidersTitle,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		GroupBox statusGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,?X!!#?Y!!#C<J,hnIz!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAezz"
		GroupBox statusGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		GroupBox statusGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		TitleBox statusText,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,B)!!#?]!!#66!!#66z!!#](Aon#azzzzzzzzzzzzzz!!#o2B4uAezz"
		TitleBox statusText,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		TitleBox statusText,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
		Slider highSliderSC,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,G0!!#@q!!#?c!!#Aoz!!#`-A7TLfzzzzzzzzzzzzzz!!#`-A7TLfzz"
		Slider highSliderSC,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		Slider highSliderSC,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		Slider lowSliderSC,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,BY!!#@q!!#?c!!#Aoz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#azz"
		Slider lowSliderSC,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
		Slider lowSliderSC,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		SetVariable slidersHighSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,G'!!#BtJ,hq;!!#<Pz!!#`-A7TLfzzzzzzzzzzzzzz!!#`-A7TLfzz"
		SetVariable slidersHighSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		SetVariable slidersHighSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		SetVariable slidersLowSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,AN!!#BtJ,hq:!!#<Pz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#azz"
		SetVariable slidersLowSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		SetVariable slidersLowSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		TitleBox slidersLimitsTitle,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,HHJ,hqN!!#?u!!#<8z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		TitleBox slidersLimitsTitle,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#AtDKKH1zzzzzzzzzzz"
		TitleBox slidersLimitsTitle,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#AtDKKH1zzzzzzzzzzzzzz!!!"
		GroupBox sliderGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,HB!!#A5!!#@T!!#?Yz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		GroupBox sliderGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#AtDKKH1zzzzzzzzzzz"
		GroupBox sliderGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#AtDKKH1zzzzzzzzzzzzzz!!!"
		SetVariable maxSetSliderSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,HG!!#A?!!#@,!!#<Pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		SetVariable maxSetSliderSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#AtDKKH1zzzzzzzzzzz"
		SetVariable maxSetSliderSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#AtDKKH1zzzzzzzzzzzzzz!!!"
		SetVariable minSetSliderSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,HHJ,hr)!!#@&!!#<Pz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		SetVariable minSetSliderSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#AtDKKH1zzzzzzzzzzz"
		SetVariable minSetSliderSV,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#AtDKKH1zzzzzzzzzzzzzz!!!"
		Button autoCalcButton,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,HG!!#Ag!!#?m!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		Button autoCalcButton,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#AtDKKH1zzzzzzzzzzz"
		Button autoCalcButton,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#AtDKKH1zzzzzzzzzzzzzz!!!"
		CheckBox holdAtEndsCheck,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,CT!!#C+J,hq_!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
		CheckBox holdAtEndsCheck,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		CheckBox holdAtEndsCheck,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"	
		CheckBox reverseTableCheck,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,H5!!#C+J,hq?!!#<8z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		CheckBox reverseTableCheck,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		CheckBox reverseTableCheck,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		GroupBox presetsGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,?X!!#C6J,hsgJ,hopz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
		GroupBox presetsGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		GroupBox presetsGroup,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		TitleBox presetsLabel,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,B)!!#C9!!#AJ!!#<8z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
		TitleBox presetsLabel,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		TitleBox presetsLabel,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		Button savePreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,B)!!#CDJ,hpC!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
		Button savePreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		Button savePreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		Button applyPreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,G?!!#CDJ,hpC!!#<Xz!!#`-A7TLfzzzzzzzzzzzzzz!!#`-A7TLfzz"
		Button applyPreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		Button applyPreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		Button applyAllPreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,Hc!!#CDJ,hpC!!#<Xz!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
		Button applyAllPreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		Button applyAllPreset,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		SetVariable currentPresetSettings,win=ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!,BY!!#COJ,hsXJ,hlsz!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
		SetVariable currentPresetSettings,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#?(FEDG<zzzzzzzzzzz"
		SetVariable currentPresetSettings,win=ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
		SetWindow ColorTableControlPanel,userdata(ResizeControlsInfo)= A"!!*'\"z!!#CAJ,ht2zzzzzzzzzzzzzzzzzzzzz"
		SetWindow ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
		SetWindow ColorTableControlPanel,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
		SetWindow ColorTableControlPanel, hook(ResizeControls)=ResizeControls#ResizeControlsHook
		SetWindow ColorTableControlPanel, hook(panelHook)=WinHook   //// The local hook function needs to be called before the ResizeControls#ResizeControlsHook.  Declaring it second ensures it is called first.

	endif
	
	UpdateControlPanel()
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////// Update Functions //////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// UpdateControlPanel ////
//// - populate the graph objects list
//// - set the current object to the first object in the list (could save selected object for each graph in the package data - possible TODO)
//// - set the color table to be the color table of the current object
//// - set all other controls to reflect the condition of the current object
//// - if there's no z colored objects on the top graph disable the controls.
Function UpdateControlPanel()
	DFREF colorTablePackageDFR = GetColorTableControlPanelDFR()
	String /G colorTablePackageDFR:topGraphName
	SVAR topGraphName = colorTablePackageDFR:topGraphName
	topGraphName = WinName(0,1)
		
	String traceNames = getZColoredObjectsFromTopWin()
	
	String cmd = GetIndependentModuleName()+"#getZColoredObjectsFromTopWin()"
	PopupMenu selectTracePU win=ColorTableControlPanel, value=#cmd
	
	if (CmpStr(traceNames, "_none_"))   /// CmpStr returns 0 if it matches, so this checks that the trace name is not "_none_"
		ControlInfo /W=ColorTableControlPanel selectTracePU
		
		String currObject=S_Value
		if (FindListItem(S_Value, traceNames) < 0) //StringFromList(0, traceNames)
			currObject = StringFromList(0, traceNames)
			PopupMenu selectTracePU, win=ColorTableControlPanel, mode=1
		endif
		
		if (strlen(currObject))		/// there's at least one graph object 
			PopupMenu selectTracePU win=ColorTableControlPanel, disable=0
			Slider highSliderSC, win=ColorTableControlPanel, disable=0
			Slider lowSliderSC, win=ColorTableControlPanel, disable=0
			Checkbox holdAtEndsCheck, win=ColorTableControlPanel, disable=0
			SetVariable slidersHighSV, win=ColorTableControlPanel, disable=0
			SetVariable slidersLowSV, win=ColorTableControlPanel, disable=0
			TitleBox slidersTitle, win=ColorTableControlPanel, disable=0		
			TitleBox presetsLabel, win=ColorTableControlPanel, disable=0
			Button savePreset, win=ColorTableControlPanel, disable=0
			Button applyPreset, win=ColorTableControlPanel, disable=0
			Button applyAllPreset, win=ColorTableControlPanel, disable=0
			SetVariable currentPresetSettings, win=ColorTableControlPanel, disable=0
			Checkbox reverseTableCheck, win=ColorTableControlPanel, disable=0
		
			Struct zInfoStruct zInfo
			getZInfoFromObject(currObject, zInfo)
			
			if (zInfo.flags & cZInfoIsCIndex)
				PopupMenu selectColorTablePU, win=ColorTableControlPanel, disable=1
				TitleBox cIndexInUse, win=ColorTableControlPanel, title="Color Index Wave: "+zInfo.colorTable, disable=0, fcolor=(65535, 0, 0)
				TitleBox slidersTitle, win=ColorTableControlPanel, title="Modify Color Index Wave Scaling"
			else
				PopupMenu selectColorTablePU, win=ColorTableControlPanel, disable=0		
				TitleBox cIndexInUse, win=ColorTableControlPanel, disable=1	
				TitleBox slidersTitle, win=ColorTableControlPanel, title="Modify Color Table Range"
			endif
			
			Wave /Z zWave = $(zInfo.zWaveDataFolder + zInfo.zWaveName)
			if (!waveExists(zWave))
				zInfo.flags = zInfo.flags | cZInfoGraphObjectMissing
			endif
			
			Variable zMax=waveMax(zWave), zMin=waveMin(zWave)
	
			if (!(zInfo.flags & cZInfoIsCIndex))
				PopupMenu selectColorTablePU, win=ColorTableControlPanel, mode=WhichListItem(zInfo.colorTable, CTabList(), ";", 0, 0)+1
			endif
			
			/////// update the panel values ///////
			controlInfo /W=ColorTableControlPanel highSliderSC
			Variable sliderIncrement = V_Height*2
		
			DFREF CTCPRef = GetColorTableControlPanelDFR()
			Wave /Z sliderTicks = CTCPRef:WMSliderTicks
			Wave /T/Z sliderTickLabels = CTCPRef:WMSliderTickLabels
			if (!WaveExists(sliderTicks) || !WaveExists(sliderTickLabels))
				InitColorTableControlPanel(CTCPRef)
				Wave /Z sliderTicks = CTCPRef:WMSliderTicks
				Wave /T/Z sliderTickLabels = CTCPRef:WMSliderTickLabels
			endif
			
			Variable sliderMin=zMin, sliderMax=zMax	
			String objectUserData = GetUserData(WinName(0,1), "", zInfo.objName)	
			String sliderMinMaxStr = StringByKey(zInfo.objType+"_sliderLimits", objectUserData,"=")  			
			if (strlen(sliderMinMaxStr))
				String sliderMinStr = StringFromList(0, sliderMinMaxStr[1,strlen(sliderMinMaxStr)-2], ",")
				String sliderMaxStr = StringFromList(1, sliderMinMaxStr[1,strlen(sliderMinMaxStr)-2], ",")
				if (CmpStr("*", sliderMinStr))
					sliderMin = str2num(sliderMinStr)			
				endif
				if (CmpStr("*", sliderMaxStr))
					sliderMax = str2num(sliderMaxStr)	
				endif
			endif

			sliderTicks = {sliderMin, (sliderMin+sliderMax)/2, sliderMax}
			String labelStr
			sprintf labelStr, "%.2e", sliderMin
			sliderTickLabels[0] = labelStr
			sprintf labelStr, "%.2e", (sliderMin+sliderMax)/2
			sliderTickLabels[1] = labelStr
			sprintf labelStr, "%.2e", sliderMax
			sliderTickLabels[2] = labelStr
			
			Slider highSliderSC, win=ColorTableControlPanel, limits={sliderMin, sliderMax, (sliderMax-sliderMin)/sliderIncrement}, value=zInfo.zMax, userTicks={sliderTicks, sliderTickLabels}
			Slider lowSliderSC, win=ColorTableControlPanel, limits={sliderMin, sliderMax, (sliderMax-sliderMin)/sliderIncrement}, value=zInfo.zMin, userTicks={sliderTicks, sliderTickLabels}
		
			//// Sliders min/max set variables
			SetVariable maxSetSliderSV, win=ColorTableControlPanel, value=_NUM:sliderMax 
			SetVariable minSetSliderSV, win=ColorTableControlPanel, value=_NUM:sliderMin

			//// sliders positions set variables
			SetVariable slidersHighSV, win=ColorTableControlPanel, value=_NUM:zInfo.zMax, limits={sliderMin, sliderMax, 0}
			SetVariable slidersLowSV, win=ColorTableControlPanel, value=_NUM:zInfo.zMin, limits={sliderMin, sliderMax, 0}
			
			ControlUpdate /W=ColorTableControlPanel highSliderSC
			ControlUpdate /W=ColorTableControlPanel lowSliderSC
			Checkbox reverseTableCheck, win=ColorTableControlPanel, value=zInfo.revColorTable, disable=2*(zInfo.flags & cZInfoIsCIndex)/cZInfoIsCIndex //revColorTable
					
			//// Update the status box
			handleError(zInfo)
		endif
	else       //// no z colored graph objects.  disable the controls
		PopupMenu selectTracePU win=ColorTableControlPanel, disable=2
		Slider highSliderSC, win=ColorTableControlPanel, disable=2
		Slider lowSliderSC, win=ColorTableControlPanel, disable=2
		PopupMenu selectColorTablePU, win=ColorTableControlPanel, disable=2
		Checkbox holdAtEndsCheck, win=ColorTableControlPanel, disable=2
		SetVariable slidersHighSV, win=ColorTableControlPanel, disable=2
		SetVariable slidersLowSV, win=ColorTableControlPanel, disable=2
		TitleBox slidersTitle, win=ColorTableControlPanel, disable=2		
		TitleBox presetsLabel, win=ColorTableControlPanel, disable=2
		Button savePreset, win=ColorTableControlPanel, disable=2
		Button applyPreset, win=ColorTableControlPanel, disable=2
		Button applyAllPreset, win=ColorTableControlPanel, disable=2
		SetVariable currentPresetSettings, win=ColorTableControlPanel, disable=2
		TitleBox cIndexInUse, win=ColorTableControlPanel, disable=1	
		Checkbox reverseTableCheck, win=ColorTableControlPanel, disable=2
		
		TitleBox statusText, win=ColorTableControlPanel, title="No z colored objects in the current graph"
	endif
End

//// Prints an error in the status box.  
//// The status box only shows 2 lines, so order the messages in order of importance.
Function handleError(zInfo)
	Struct zInfoStruct & zInfo
	
	DFREF colorTablePackageDFR = GetColorTableControlPanelDFR()
	
	String /G colorTablePackageDFR:errStr = ""
	SVAR errStr = colorTablePackageDFR:errStr
	SVAR topGraphName = colorTablePackageDFR:topGraphName

	DoWindow $topGraphName
	if (!V_flag)
		UpdateControlPanel()
	endif
	
	if (zInfo.flags & cZInfoGraphObjectMissing)
		if (strlen(errStr))
			errStr += "\r"
		endif
		strswitch (zInfo.objType)
			case "image":
				errStr += "Error: image "+zInfo.objName+" does not exist in the top graph "+topGraphName+"."
				break
			case "trace":
				errStr += "Error: wave "+zInfo.objName+" does not exist in the top graph "+topGraphName+"."			
				break
			case "contour":
				errStr += "Error: contour "+zInfo.objName+" does not exist in the top graph "+topGraphName+"."
				break
			default:
				break
		endswitch
	endif
	if (zInfo.flags & cZInfoCIndexWaveMissing)
		if (strlen(errStr))
			errStr += "\r"
		endif
		errStr += "Error: color index wave "+zInfo.colorTable+" does not exist."
	endif

	if (zInfo.flags & cZInfoCIndexHighEqLow)
		if (strlen(errStr))
			errStr += "\r"
		endif
		errStr += "Error: a color index wave cannot have a first value equal the last value."
	endif
	
	if (zInfo.flags & cZInfoIsCIndex)
		if (strlen(errStr))
			errStr += "\r"
		endif
		errStr += "Warning: changes will affect the x scaling of the color index wave.\r"
		errStr += "Note: Use the sliders to reverse the color table."
	endif
	
	TitleBox statusText, win=ColorTableControlPanel, variable=errStr, fcolor=(65535, 0, 0)
End	

//// UpdateTopGraph() ////
//// - find the current selected trace
//// - get values of all the controls and set the graph objects values accordingly
Function UpdateTopGraph()
	ControlInfo /W=ColorTableControlPanel selectTracePU
	String selectedTrace = S_Value
	
	ControlInfo /W=ColorTableControlPanel selectColorTablePU
	String selectedColorTable = S_Value
	
	ControlInfo /W=ColorTableControlPanel highSliderSC
	Variable vh= V_Value
	ControlInfo /W=ColorTableControlPanel lowSliderSC
	Variable vl= V_Value
	
	ControlInfo /W=ColorTableControlPanel reverseTableCheck
	Variable revCT = V_Value
		
	Struct zInfoStruct zInfo
	getZInfoFromObject(selectedTrace, zInfo)
	
	if (strlen(zInfo.zWaveName))
		updateGraphObject(zInfo, vl, vh, selectedColorTable, revCT)
	endif
End

///// Set minVal or maxVal to NaN to auto calculate
///// This function simply changes the userdata for the named graph object in the top graph.  It uses the name as it appears in the popup with "_" prepended,
///// which includes the type information (trace, image or countour), so it should not interfere with user data.
Function setSliderLimits(minVal, maxVal, [doUp, currObject])
	Variable minVal, maxVal
	Variable doUp
	String currObject

	String minValStr, maxValStr
	
	if (ParamIsDefault(doUp))
		doUp = 1
	endif
	if (ParamIsDefault(currObject))
		ControlInfo /W=ColorTableControlPanel selectTracePU
		currObject=S_Value
	endif
	
	Struct zInfoStruct zInfo
	getZInfoFromObject(currObject, zInfo)
	Wave /Z zWave = $(zInfo.zWaveDataFolder + zInfo.zWaveName)
	if (!waveExists(zWave))
		zInfo.flags = zInfo.flags | cZInfoGraphObjectMissing
		handleError(zInfo)
	endif
	
	if (numType(minVal)==2)
		minValStr = "*"
		minVal = waveMin(zWave)
	else
		minValStr = num2str(minVal)
	endif
	if (numType(maxVal)==2)
		maxValStr = "*"
		maxVal = waveMax(zWave)
	else	
		maxValStr = num2str(maxVal)
	endif
	
	String objectUserData = GetUserData(WinName(0,1), "", zInfo.objName)	
	objectUserData = ReplaceStringByKey(zInfo.objType+"_sliderLimits", objectUserData, "{"+minValStr+","+maxValStr+"}", "=")
	SetWindow 	$(WinName(0,1)) userdata($(zInfo.objName))=objectUserData
	
	Variable sliderMin=zInfo.zMin, sliderMax=zInfo.zMax
	if (sliderMin < minVal)
		sliderMin = minVal
	elseif (sliderMin > maxVal)
		sliderMin = maxVal
	endif
	if (sliderMax < minVal)
		sliderMax = minVal
	elseif (sliderMax > maxVal)
		sliderMax = maxVal
	endif	
	
	updateGraphObject(zInfo, sliderMin, sliderMax, "", zInfo.revColorTable)
	
	if (doUp)
		UpdateControlPanel()   ////update the control panel
	endif
End

//// Getting the slider min/max should be part of ControlInfo, but it is not.  This function tries to get it from the graph's user data.
//// if its not set (generally it will not be), then get it from the current graph object's underlying data
Function getCurrentSliderMinMax(minVar, maxVar)
	Variable & minVar
	Variable & maxVar
	
	ControlInfo /W=ColorTableControlPanel selectTracePU	
	String currObject=S_Value

	if (strlen(currObject))		/// there's at least one graph object	
		Struct zInfoStruct zInfo
		getZInfoFromObject(currObject, zInfo)
		
		Wave /Z zWave = $(zInfo.zWaveDataFolder + zInfo.zWaveName)
		if (!waveExists(zWave))
			zInfo.flags = zInfo.flags | cZInfoGraphObjectMissing
			handleError(zInfo)
			
			UpdateControlPanel()
		endif
		
		Variable zMax=waveMax(zWave), zMin=waveMin(zWave)

		/////// update the panel values ///////
		minVar=zMin
		maxVar=zMax
		
		String objectUserData = GetUserData(WinName(0,1), "", zInfo.objName)	
		String sliderMinMaxStr = StringByKey(zInfo.objType+"_sliderLimits", objectUserData,"=")  
		if (strlen(sliderMinMaxStr))
			String sliderMinStr = StringFromList(0, sliderMinMaxStr[1,strlen(sliderMinMaxStr)-2], ",")
			String sliderMaxStr = StringFromList(1, sliderMinMaxStr[1,strlen(sliderMinMaxStr)-2], ",")
			if (CmpStr("*", sliderMinStr))
				minVar = str2num(sliderMinStr)			
			endif
			if (CmpStr("*", sliderMaxStr))
				maxVar = str2num(sliderMaxStr)	
			endif
		endif
	else
		minVar = NaN
		maxVar = NaN
	endif
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////// Event Functions ///////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// remember the panel position and size
//// when the panel is activated update the controls
Function WinHook(s)
	STRUCT WMWinHookStruct &s

	Variable rval= 0
	strswitch(s.eventName)
		case "kill":
			Execute/P/Q/Z "DELETEINCLUDE <Color Table Control Panel>"
			Execute/P/Q/Z "COMPILEPROCEDURES "		
			break
		case "activate":
			UpdateControlPanel()		
			break
		case "resize":
			UpdateControlPanel()
		case "moved":		
			DFREF CTCPRef = GetColorTableControlPanelDFR()
			NVAR /Z panelHeight = CTCPRef:PanelHeight 
			NVAR /Z panelWidth = CTCPRef:PanelWidth
			NVAR /Z xLocation = CTCPRef:xLocation
			NVAR /Z yLocation = CTCPRef:yLocation
			
			if (!NVAR_exists(panelHeight) || !NVAR_exists(panelWidth) || !NVAR_exists(xLocation) || !NVAR_exists(yLocation))
				InitColorTableControlPanel(CTCPRef)
				NVAR panelHeight = CTCPRef:PanelHeight 
				NVAR panelWidth = CTCPRef:PanelWidth
				NVAR xLocation = CTCPRef:xLocation
				NVAR yLocation = CTCPRef:yLocation
			endif
			
			GetWindow ColorTableControlPanel wsize	
			panelHeight = V_bottom-V_top
			panelWidth = V_right-V_left
			yLocation = V_top
			xLocation = V_left
			break
		default:
			break
	endswitch
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////// Control Functions //////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function sliderLimitsSetVarProc(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
	
	switch (SV_Struct.eventCode)
		case 2:
			Variable minVar, maxVar
			getCurrentSliderMinMax(minVar, maxVar)   //// minVar and maxVar are the "first" and "last" sliders, respectively.
			
			if (!CmpStr(SV_Struct.ctrlName, "maxSetSliderSV"))	
				maxVar = SV_Struct.dval
			else
				minVar = SV_Struct.dval
			endif

			Variable trueMin = min(minVar, maxVar)    //// they may not be the true min or max
			Variable trueMax = max(minVar, maxVar)

			setSliderLimits(minVar, maxVar)
			
			Variable highSliderVal, lowSliderVal
			ControlInfo /W=ColorTableControlPanel highSliderSC
			highSliderVal = V_Value
			ControlInfo /W=ColorTableControlPanel lowSliderSC
			lowSliderVal = V_Value

			STRUCT WMSliderAction sa
			sa.win=SV_Struct.win
			sa.eventCode=9

			Variable updateCalled = 0
			if (highSliderVal < trueMin)
				Slider highSliderSC, win=ColorTableControlPanel, value=trueMin
				sa.ctrlName = "highSliderSC" 
				sa.curval=trueMin
				SliderProc(sa)
				updateCalled = 1  //// SliderProc will update the top graph.  No need to do it again
			elseif (highSliderVal > trueMax)
				Slider highSliderSC, win=ColorTableControlPanel, value=trueMax
				sa.ctrlName = "highSliderSC" 
				sa.curval=trueMax
				SliderProc(sa)	
				updateCalled = 1 //// SliderProc will update the top graph.  No need to do it again
			endif
			
			if (lowSliderVal < trueMin)
				Slider lowSliderSC, win=ColorTableControlPanel, value=trueMin
				sa.ctrlName = "lowSliderSC" 
				sa.curval=trueMin
				SliderProc(sa) 
				updateCalled = 1 //// SliderProc will update the top graph.  No need to do it again
			elseif (lowSliderVal > trueMax)
				Slider lowSliderSC, win=ColorTableControlPanel, value=trueMax
				sa.ctrlName = "lowSliderSC" 
				sa.curval=trueMax
				SliderProc(sa) 
				updateCalled = 1 //// SliderProc will update the top graph.  No need to do it again
			endif
	
			if (!updateCalled)
				updateTopGraph()
			endif
	
			break
		default:
			break
	endswitch
End

//// Auto calc button.  Simply call set Slider limits with NaN arguments to set slider limits according to the current graph object
Function sliderLimitsAutoCalc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	switch (B_Struct.eventCode)
		case 2: //// Mouse up
			setSliderLimits(NaN, NaN)			
			break
		default:
			break
	endswitch
End

//// Save the current control settings
Function SavePreset(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventCode==2)
		DFREF CTCPRef = GetColorTableControlPanelDFR()
	
		NVAR /Z highSliderPreset = CTCPRef:WMHighSliderPreset 
		NVAR /Z lowSliderPreset = CTCPRef:WMLowSliderPreset
		SVAR /Z colorTablePreset = CTCPRef:WMColorTablePreset 	
		NVAR /Z highSliderPresetLimit = CTCPRef:WMHighSliderLimitPreset
		NVAR /Z lowSliderPresetLimit = CTCPRef:WMLowSliderLimitPreset	
		NVAR /Z revColorTable = CTCPRef:WMReverseColorTablePreset
		
		if (!NVAR_exists(highSliderPreset) || !NVAR_exists(lowSliderPreset) || !SVAR_exists(colorTablePreset) ||!NVAR_exists(revColorTable))
			InitColorTableControlPanel(CTCPRef)
			NVAR highSliderPreset = CTCPRef:WMHighSliderPreset 
			NVAR lowSliderPreset = CTCPRef:WMLowSliderPreset
			SVAR colorTablePreset = CTCPRef:WMColorTablePreset 
			NVAR highSliderPresetLimit = CTCPRef:WMHighSliderLimitPreset
			NVAR lowSliderPresetLimit = CTCPRef:WMLowSliderLimitPreset
			NVAR revColorTable = CTCPRef:WMReverseColorTablePreset
		endif
		
		ControlInfo /W=ColorTableControlPanel selectColorTablePU
		if (strlen(S_Value))
			colorTablePreset = S_Value
		endif
		ControlInfo /W=ColorTableControlPanel highSliderSC
		if (numtype(V_Value)!=2)
			highSliderPreset = V_Value
		endif
		ControlInfo /W=ColorTableControlPanel lowSliderSC
		if (numtype(V_Value)!=2)
			lowSliderPreset = V_Value
		endif	
		ControlInfo /W=ColorTableControlPanel maxSetSliderSV
		if (numtype(V_Value)!=2)
			highSliderPresetLimit = V_Value
		endif
		ControlInfo /W=ColorTableControlPanel minSetSliderSV
		if (numtype(V_Value)!=2)
			lowSliderPresetLimit = V_Value
		endif
		ControlInfo /W=ColorTableControlPanel reverseTableCheck
		revColorTable = V_Value
				
		String presetSettings
		sprintf presetSettings, "{%.2e, %.2e, %s, %d}", lowSliderPreset, highSliderPreset, colorTablePreset, revColorTable
		SetVariable currentPresetSettings, win=ColorTableControlPanel, value=_STR:presetSettings
	endif
End

//// apply the saved control settings to the current graph object, or to all graph objects
Function ApplyPreset(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventCode==2)
		DFREF CTCPRef = GetColorTableControlPanelDFR()
	
		NVAR /Z highSliderPreset = CTCPRef:WMHighSliderPreset 
		NVAR /Z lowSliderPreset = CTCPRef:WMLowSliderPreset
		SVAR /Z colorTablePreset = CTCPRef:WMColorTablePreset 
		NVAR /Z highSliderPresetLimit = CTCPRef:WMHighSliderLimitPreset
		NVAR /Z lowSliderPresetLimit = CTCPRef:WMLowSliderLimitPreset			
		NVAR /Z revColorTable = CTCPRef:WMReverseColorTablePreset
		
		if (!NVAR_exists(highSliderPreset) || !NVAR_exists(lowSliderPreset) || !SVAR_exists(colorTablePreset) || !NVAR_exists(revColorTable))
			InitColorTableControlPanel(CTCPRef)
			NVAR highSliderPreset = CTCPRef:WMHighSliderPreset 
			NVAR lowSliderPreset = CTCPRef:WMLowSliderPreset
			SVAR colorTablePreset = CTCPRef:WMColorTablePreset 
			NVAR highSliderPresetLimit = CTCPRef:WMHighSliderLimitPreset
			NVAR lowSliderPresetLimit = CTCPRef:WMLowSliderLimitPreset
			NVAR revColorTable = CTCPRef:WMReverseColorTablePreset			
		endif
			
		if (numtype(highSliderPreset) != 2 && numtype(lowSliderPreset)!=2 && strlen(colorTablePreset)!=0 && CmpStr(colorTablePreset, "_none_"))
			String objectsList = ""
			ControlInfo /W=ColorTableControlPanel selectTracePU
			String selectedTrace = S_Value
			if (!CmpStr(B_Struct.ctrlName, "applyAllPreset"))
				objectsList = getZColoredObjectsFromTopWin()
			else
				if (CmpStr(selectedTrace, "_none_"))
					objectsList = selectedTrace + ";"
				endif
			endif
	
			Variable i
			Struct zInfoStruct zInfo
			for (i=0; i<ItemsInList(objectsList); i+=1)
				String currObject = StringFromList(i, objectsList)
				getZInfoFromObject(currObject, zInfo)
		
				setSliderLimits(lowSliderPresetLimit, highSliderPresetLimit, doUp=0, currObject=currObject)
				
				if (strlen(zInfo.zWaveName))
					updateGraphObject(zInfo, lowSliderPreset, highSliderPreset, colorTablePreset, revColorTable)				
				endif
			endfor
		endif
		UpdateControlPanel()
	endif
End

Function Help(ctrlName) : ButtonControl
	String ctrlName
	
	DisplayHelpTopic "Color Table Control Panel"	
End

Function SelectTraceProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case -1: // control being killed
			break
		case 2:
			UpdateControlPanel()
			break
		default:
			break
	endswitch
End

Function SelectColorTableProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case -1: // control being killed
			break
		case 2:			
			UpdateTopGraph()
			break
		default:
			break
	endswitch
End

Function reverseColorTableProc(CB_Struct) : CheckBoxControl
	STRUCT WMCheckBoxAction &CB_Struct
	
	switch( CB_Struct.eventCode )
		case -1: // control being killed
			break
		case 2:			
			UpdateTopGraph()
			break
		default:
			break
	endswitch
End

Function setVarProc(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
	
	switch( SV_Struct.eventCode )
		case -1:
			break
		case 2:
			SV_Struct.blockReentry=1			
			///// the tricky bits regarding holding the high-low difference are all in the slider control function.  Probably should remove it, but
			///// its currently a bit of a tangle.  Set the appropriate slider, create a slider action struct and call the slider proc.  
			STRUCT WMSliderAction sa
			sa.win=SV_Struct.win
			sa.eventCode=9
			sa.curval = SV_Struct.dval
			
			if (!CmpStr(SV_Struct.ctrlName, "slidersHighSV"))		
				Slider highSliderSC, win=ColorTableControlPanel, value=SV_Struct.dval
				sa.ctrlName = "highSliderSC"
			else
				Slider lowSliderSC, win=ColorTableControlPanel, value=SV_Struct.dval
				sa.ctrlName = "lowSliderSC"
			endif
			SliderProc(sa)			
			
			break
		default:
			break
	endswitch
End

Function SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		case 9:  // mouse moved && mouse down
			sa.blockReentry=1
		
			//// get general slider conditions - assumes limits are the same for all sliders
			ControlInfo /W=ColorTableControlPanel highSliderSC
			String recreation = S_recreation
			Variable index, i		
			
			Variable iLimitsStart = strsearch(recreation, "limits={",0)   // find the location of the recreation string containing slider limits data
			if (iLimitsStart >= 0)
				Variable iLimitsEnd = strsearch(recreation, "}",iLimitsStart)   // the location of the end of the limits data
				String limitsStr = recreation[iLimitsStart+8, iLimitsEnd-1]      // get the string
				Variable minVal = str2num(StringFromList(0, limitsStr, ","))   // get the pieces of info needed
				Variable maxVal = str2num(StringFromList(1, limitsStr, ","))
							
				ControlInfo /W=ColorTableControlPanel selectTracePU
				String selectedTrace = S_Value
				Struct zInfoStruct zInfo
				getZInfoFromObject(selectedTrace, zInfo)
								
				DFREF colorTablePackageDFR = GetColorTableControlPanelDFR()
				NVAR holdEnds = colorTablePackageDFR:WMHoldAtEnds
			
				Variable lowVal, highVal
				if (!CmpStr(sa.ctrlName, "highSliderSC"))
					highVal = sa.curval
					lowVal = zInfo.zMin
				else
					highVal = zInfo.zMax
					lowVal = sa.curval
				endif
			
				if (holdEnds)
					Variable difference = zInfo.zMax - zInfo.zMin
					
					if (!CmpStr(sa.ctrlName, "highSliderSC"))
						if (sa.curval - difference < minVal)
							highVal = minVal+difference
							lowVal = minVal
						elseif (sa.curval - difference > maxVal)
							highVal = maxVal+difference
							lowVal = maxVal
						else
							lowVal = sa.curval-difference
						endif
					else
						if (sa.curval + difference < minVal)
							highVal = minVal
							lowVal = minVal-difference
						elseif (sa.curval + difference > maxVal)
							highVal = maxVal
							lowVal = maxVal-difference							
						else
							highVal = sa.curval+difference
						endif
					endif
				endif
				
				Slider highSliderSC, win=ColorTableControlPanel, value=highVal
				Slider lowSliderSC, win=ColorTableControlPanel, value=lowVal
				SetVariable slidersHighSV, win=ColorTableControlPanel, value=_NUM:highVal
				SetVariable slidersLowSV, win=ColorTableControlPanel, value=_NUM:lowVal
			endif		
			UpdateTopGraph()
			break
	endswitch

	return 0
End


////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// Utility Structures and  Functions /////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
Structure zInfoStruct
	String objName
	String colorTable
	String zWaveName
	String zWaveDataFolder
	String objType
	Variable flags   //// Bit-wise variable.  Constants defined with cZInfo prefix.  
	Variable zMin
	Variable zMax
	Variable revColorTable
EndStructure

///// Fill out the zInfoStruct given the name as it appears in the selectTracePU popup and as returned by getZColoredObjectsFromTopWin()
Function getZInfoFromObject(objectNameInPopUp, zInfo)
	String objectNameInPopUp
	Struct zInfoStruct & zInfo
	
	Variable iStart = strsearch(objectNameInPopUp, "(", strlen(objectNameInPopUp)-1, 1)+1
	zInfo.objType = objectNameInPopUp[iStart, strlen(objectNameInPopUp)-2]
	
	//// utility variables ////
	String info, recreation, zColorStr, zWaveName
	String highValStr, lowValStr, revColorTableStr
	
	zInfo.zWaveDataFolder = ""
	
	strswitch (zInfo.objType)
		
		case "trace":
			zInfo.objName = objectNameInPopUp[0, strlen(objectNameInPopUp)-9]
			
			info = TraceInfo("", zInfo.objName, 0)		
			recreation = StringByKey("RECREATION", info)
			zColorStr = StringByKey("zColor(x)", recreation, "=")
						
			String fullPathWaveName = StringFromList(0, zColorStr[1,strlen(zColorStr)-2], ",")
			
			zInfo.zWaveName = PossiblyQuoteName(ParseFilePath(0, fullPathWaveName, ":", 1, 0))
			String possibleRelativePath = fullPathWaveName[0, strlen(fullPathWaveName)-strlen(zInfo.zWaveName)-1]
			if (strlen(possibleRelativePath)==0)
				possibleRelativePath = "root:"   // if the zWaveName is liberal the wave reference won't work with single quotes if the data is in root:
			endif
			Wave /Z zWave = $(possibleRelativePath + zInfo.zWaveName)   
			if (!waveExists(zWave))
				zInfo.flags = zInfo.flags | cZInfoGraphObjectMissing
				handleError(zInfo)
				break
			endif
			
			zInfo.zWaveDataFolder = GetWavesDataFolder(zWave, 1)
			
			highValStr = StringFromList(2, zColorStr[1,strlen(zColorStr)-2], ",")
			
			if (!CmpStr(highValStr, "*"))
				zInfo.zMax = waveMax(zWave)
			else 	
				zInfo.zMax = str2num(highValStr)
			endif
			lowValStr = StringFromList(1, zColorStr[1,strlen(zColorStr)-2], ",")
			if (!CmpStr(lowValStr, "*"))
				zInfo.zMin = waveMin(zWave)
			else 	
				zInfo.zMin = str2num(lowValStr)
			endif
			zInfo.colorTable = StringFromList(3, zColorStr[1,strlen(zColorStr)-2], ",")
		
			if (ItemsInList(zColorStr[1,strlen(zColorStr)-2], ",") > 4)
				revColorTableStr = StringFromList(4, zColorStr[1,strlen(zColorStr)-2])
				zInfo.revColorTable = str2num(revColorTableStr)
			else	
				zInfo.revColorTable = 0
			endif
		
			break
		case "image":
			zInfo.objName = objectNameInPopUp[0, strlen(objectNameInPopUp)-9]
			
			info = ImageInfo("", zInfo.objName, 0)
			recreation = StringByKey("RECREATION", info)
			zInfo.zWaveName = PossiblyQuoteName(StringByKey("ZWave", info))
			zInfo.zWaveDataFolder = StringByKey("ZWaveDF", info)
			Wave /Z zWave = $(zInfo.zWaveDataFolder + zInfo.zWaveName)
			
			if (!waveExists(zWave))
				zInfo.flags = zInfo.flags | cZInfoGraphObjectMissing
				handleError(zInfo)
				break
			endif
						
			if (NumberByKey("COLORMODE",info)==2 || NumberByKey("COLORMODE",info)==3)
				zInfo.flags = zInfo.flags | cZInfoIsCIndex   //// set the color index bit

				zColorStr = StringByKey("cindex", recreation, "=")   //// in color index context this is the path to the color index wave. 
				if (!CmpStr(zColorStr[0], " "))                                  //// also address strange space (" ") after cindex=
					zColorStr = zColorStr[1, strlen(zColorStr)-1]                        
				endif
				Wave /Z cIndexWave = $zColorStr
				if (!waveExists(cIndexWave))
					zInfo.flags = zInfo.flags | cZInfoCIndexWaveMissing
					zInfo.zMax = NaN 
					zInfo.zMin = NaN
					
					handleError(zInfo)
					break
				endif
				
				zInfo.colorTable = GetWavesDataFolder(cIndexWave, 1) + NameOfWave(cIndexWave)
				
				Variable zMin = DimOffset(cIndexWave, 0)
				Variable zMax = zMin + DimDelta(cIndexWave, 0) * (DimSize(cIndexWave, 0)-1)
				
				zInfo.revColorTable = 0		// Reverse Color Table disabled for Color Index Waves
				
				zInfo.zMin = zMin
				zInfo.zMax = zMax
			else
				zInfo.flags = zInfo.flags & ~cZInfoIsCIndex   //// clear out the color index bit
				zColorStr = StringByKey("ctab", recreation, "=")
				iStart = strsearch(zColorStr, "{", strlen(zColorStr)-2, 1)+1  /// there seems to be a space after ctab=, which seems strange so I'm not relying on the position of "{" by offset
				highValStr = StringFromList(1, zColorStr[iStart,strlen(zColorStr)-2], ",")
			
				if (!CmpStr(highValStr, "*"))
				zInfo.zMax = waveMax(zWave)
				else 	
					zInfo.zMax = str2num(highValStr)
				endif
				lowValStr = StringFromList(0, zColorStr[iStart,strlen(zColorStr)-2], ",")
				if (!CmpStr(lowValStr, "*"))
					zInfo.zMin = waveMin(zWave)
				else 	
					zInfo.zMin = str2num(lowValStr)
				endif
				zInfo.colorTable = StringFromList(2, zColorStr[iStart,strlen(zColorStr)-2], ",")
						
				if (ItemsInList(zColorStr[iStart,strlen(zColorStr)-2], ",") > 3)
					revColorTableStr = StringFromList(3, zColorStr[iStart,strlen(zColorStr)-2], ",")
					zInfo.revColorTable = str2num(revColorTableStr)
				else	
					zInfo.revColorTable = 0
				endif				
			endif

			break
		case "contour":
			zInfo.objName = objectNameInPopUp[0, strlen(objectNameInPopUp)-11]
		
			info = contourInfo("", zInfo.objName, 0) 		
			zInfo.zWaveDataFolder = StringByKey("ZWAVEDF", info)			
			zInfo.zWaveName = PossiblyQuoteName(StringByKey("ZWave", info))
			Wave /Z zWave = $(zInfo.zWaveDataFolder + zInfo.zWaveName)
	
			if (!waveExists(zWave))
				zInfo.flags = zInfo.flags | cZInfoGraphObjectMissing
				handleError(zInfo)
				return -1
			endif			
				
			zColorStr = StringByKey("ctabLines", info, "=")
			iStart = strsearch(zColorStr, "{", strlen(zColorStr)-1, 1)+1  /// there seems to be a space after ctab=, which seems strange so I'm not relying on the position of "{" by offset
			highValStr = StringFromList(1, zColorStr[iStart,strlen(zColorStr)-2], ",")
			
			if (!CmpStr(highValStr, "*"))
				zInfo.zMax = waveMax(zWave)
			else 	
				zInfo.zMax = str2num(highValStr)
			endif
			lowValStr = StringFromList(0, zColorStr[iStart,strlen(zColorStr)-2], ",")
			if (!CmpStr(lowValStr, "*"))
				zInfo.zMin = waveMin(zWave)
			else 	
				zInfo.zMin = str2num(lowValStr)
			endif
			zInfo.colorTable = StringFromList(2, zColorStr[iStart,strlen(zColorStr)-2], ",")
			if (ItemsInList(zColorStr[iStart,strlen(zColorStr)-2], ",") > 3)
				revColorTableStr = StringFromList(3, zColorStr[iStart,strlen(zColorStr)-2])
				zInfo.revColorTable = str2num(revColorTableStr)
			else	
				zInfo.revColorTable = 0
			endif				
			
			break
		default:
			break
	endswitch
End

// zInfo must be filled, presumably from a call to getZInfoFromObject()
// set low val and/or highval to NaN to use values from zInfo
// set colorTableName to "" to use the color table from zInfo
Function updateGraphObject(zInfo, lowVal, highVal, colorTableName, reverseColorTable)
	Struct zInfoStruct & zInfo
	Variable lowVal, highVal
	String colorTableName
	Variable reverseColorTable

	if (NumType(lowVal)==2)
		lowVal = zInfo.zMin
	endif
	if (NumType(highVal)==2)
		highVal = zInfo.zMax
	endif
	if (strlen(colorTableName)==0)
		colorTableName = zInfo.colorTable
	endif

	strswitch (zInfo.objType)
		case "trace":		
			ModifyGraph zColor($(zInfo.objName))={$(zInfo.zWaveDataFolder+zInfo.zWaveName), lowVal, highVal,$colorTableName,reverseColorTable}
			break
		case "image":
			if (zInfo.flags & cZInfoIsCIndex)
							
				Wave /Z cIndexWave = $(zInfo.colorTable)
				if (!waveExists(cIndexWave))
					zInfo.flags = zInfo.flags | cZInfoCIndexWaveMissing
					zInfo.zMax = NaN
					zInfo.zMin = NaN
				else
					if (lowVal!=highVal)   
						SetScale /I x, lowVal, highVal, cIndexWave			
					else
						zInfo.flags = zInfo.flags | cZInfoCIndexHighEqLow 
						if (abs(zInfo.zMin-lowVal) > abs(zInfo.zMax-highVal))
							Slider lowSliderSC, win=ColorTableControlPanel, value=zInfo.zMin
							SetVariable slidersLowSV, win=ColorTableControlPanel, value=_NUM:zInfo.zMin
						else
							Slider highSliderSC, win=ColorTableControlPanel, value=zInfo.zMax
							SetVariable slidersHighSV, win=ColorTableControlPanel, value=_NUM:zInfo.zMax
						endif
					endif
				endif
			else
				ModifyImage $(zInfo.zWaveName), ctab={lowVal, highVal, $colorTableName, reverseColorTable}
			endif
			break
		case "contour":
			ModifyContour $(zInfo.zWaveName), ctabLines={lowVal, highVal, $colorTableName, reverseColorTable}
			break
		default: 
			break
	endswitch
	handleError(zInfo)
End

//// Get a string list of all graph objects using a mapping from data values to a color table.  ID the type in the string.
Function /S getZColoredObjectsFromTopWin()
	String traceList = TraceNameList("", ";", 5)
	
	String currObject, currImage, info, ret=""
	Variable i
	for (i=0; i<ItemsInList(traceList); i+=1)
		currObject = StringFromList(i, traceList)
		info = TraceInfo("", currObject, 0)
		String recreation = StringByKey("RECREATION", info)
		String zColorStr = StringByKey("zColor(x)", recreation, "=")
		
		if (strlen(zColorStr) && CmpStr(zColorStr, "0"))
			ret += currObject+" (trace);"
		endif
	endfor

	String imageList = ImageNameList("", ";")
	for(i=0; i<ItemsInList(imageList); i+=1)
		currImage = StringFromList(i, imageList)
		info = ImageInfo("", currImage, 0)
		Variable isCT= NumberByKey("COLORMODE",info)==1 || NumberByKey("COLORMODE",info)==2 || NumberByKey("COLORMODE",info)==3	// only color table or color index images
		if( isCT )
			ret += currImage+" (image);"
		endif
	endfor

	///// add all contours? they should all have z values 
	String contourList = ContourNameList("", ";")
	for (i=0; i<ItemsInList(contourList); i+=1)
		ret+=StringFromList(i, contourList)+" (contour);"
	endfor
	
	if (!strlen(ret))
		ret="_none_"
	endif
	
	return ret
End

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// Get Set Package Data Folder ///////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

Function InitColorTableControlPanel(dfr)
	DFREF dfr

	Variable localVar
	String localStr

	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMHoldAtEnds", 0)
	Variable /G dfr:WMHoldAtEnds = localVar
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMHighSliderPreset", NaN)
	Variable /G dfr:WMHighSliderPreset =  localVar
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMLowSliderPreset", NaN)
	Variable /G dfr:WMLowSliderPreset =  localVar
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMHighSliderLimitPreset", NaN)
	Variable /G dfr:WMHighSliderLimitPreset =  localVar
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMLowSliderLimitPreset", NaN)
	Variable /G dfr:WMLowSliderLimitPreset =  localVar
	localStr = StrVarOrDefault("root:Packages:ColorTableControlPanel:WMColorTablePreset", "")
	String /G dfr:WMColorTablePreset =  localStr		
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:PanelHeight", Height)
	Variable /G dfr:PanelHeight = max(localVar, Height)
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:PanelWidth", Width)
	Variable /G dfr:PanelWidth = max(localVar, Width)
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:xLocation", 20)
	Variable /G dfr:xLocation = localVar
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:yLocation", 20)
	Variable /G dfr:yLocation = localVar
//	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMReverseColorTable", 0)
//	Variable /G dfr:WMReverseColorTable = localVar
	localVar = NumVarOrDefault("root:Packages:ColorTableControlPanel:WMReverseColorTablePreset", 0)
	Variable /G dfr:WMReverseColorTablePreset = localVar
	
	Wave /Z testWaveRef = dfr:WMSliderTicks
	if (!WaveExists(testWaveRef))
		Make /D/N=3 dfr:WMSliderTicks
	endif
	Wave /Z testWaveRef = dfr:WMSliderTickLabels
	if (!WaveExists(testWaveRef))
		Make /T/N=3 dfr:WMSliderTickLabels
	endif
End

// Creates the data folder if it does not already exist.
Function /DF GetColorTableControlPanelDFR()
	DFREF dfr = root:Packages:ColorTableControlPanel
	if (DataFolderRefStatus(dfr) != 1)
		NewDataFolder/O root:Packages
		NewDataFolder/O root:Packages:ColorTableControlPanel
		DFREF dfr = root:Packages:ColorTableControlPanel
		
		InitColorTableControlPanel(dfr)
	endif
	return dfr
End