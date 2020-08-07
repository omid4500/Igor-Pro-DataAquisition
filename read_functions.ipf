#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This is a prototype function for all read functions.
// meaning that all read functions should accept one numeric variable, hopefully the instrument ID
// and return one number
function read_prototype(instr_ID)
	variable instr_ID
	return 0.0
end

function/s log_prototype(instr_ID)
	variable instr_ID
	return ""
end

//--------DMM--------------------
function read_dc(instr_ID)
	variable instr_ID
	return readdmm(instr_ID)
end
function/s log_dmm(instr_ID)
	variable instr_ID
	return ""
end

//--------Lock-in----------------
function read_loM(instr_ID)
	variable instr_ID
	return Lockin_M_VISA(instr_ID)
end

function read_loPh(instr_ID)
	variable instr_ID
	return Lockin_Ph_VISA(instr_ID)
end

function read_loX(instr_ID)
	variable instr_ID
	return Lockin_X_VISA(instr_ID)
end
function read_loY(instr_ID)
	variable instr_ID
	return Lockin_Y_VISA(instr_ID)
end
function/s log_Lock_in(instr_ID)
	variable instr_ID
	return Lockin_Status(instr_ID)
end

//--------AVS-------------------
function read_R1K(instr_ID)
	variable instr_ID
	setChannel_AVS_VISA(instr_ID,1)
	wait(10)
	return readRes_AVS_VISA(instr_ID)
end

function read_Rstil(instr_ID)
	variable instr_ID
	setChannel_AVS_VISA(instr_ID,2)
	wait(10)
	return readRes_AVS_VISA(instr_ID)
end

function read_Rmc(instr_ID)
	variable instr_ID
	setChannel_AVS_VISA(instr_ID,3)
	wait(10)
	return readRes_AVS_VISA(instr_ID)
end

//--------AVS-------------------
function read_PIVC(instr_ID)
	variable instr_ID
	return read_pressure(1)
end

function read_PSTIL(instr_ID)
	variable instr_ID
	return read_pressure(2)
end
function/s log_AVS(instr_ID)
	variable instr_ID
	return "" // TODO
end

//--------Keithley----------------
function read_KeithleyV(instr_ID)
	variable instr_ID
	return getK2400voltage(instr_ID)
end
function read_KeithleyI(instr_ID)
	variable instr_ID
	return getK2400current(instr_ID)
end
function/s log_Keithley(instr_ID)
	variable instr_ID
	return getK2400Status(instr_ID)
end

//--------    IPS   -------------
function read_IPSB(instr_ID)
	variable instr_ID
	return read_param_IPS_VISA(instr_ID, 7)
end
function read_IPSI(instr_ID)
	variable instr_ID
	return read_param_IPS_VISA(instr_ID, 0)
end
function read_IPSsweeprate(instr_ID)
	variable instr_ID
	return read_param_IPS_VISA(instr_ID, 9)
end
function/s log_IPS(instr_ID)
	variable instr_ID
	return IPS_Status(instr_ID)
end

//-----------AVS Temps------------
function read_T1k(instr_ID)
	variable instr_ID
	setChannel_AVS_VISA(instr_ID,0)
	wait(15)
	variable Res0=readRes_AVS_VISA(instr_ID)
	variable Temp1kpot
	variable G=log(Res0);
	variable I=79362.66285435;
	variable J=-134213.208617999;
	variable K=101026.7304322;
	variable L=-44413.273683345;
	variable M=12564.321465816;
	variable N=-2371.588181102;
	variable O=298.641277814;
	variable P=-24.188904628;
	variable Q=1.143358358;
	variable R=-0.024026573;
	Temp1kpot=I+G*J+G^2*K+G^3*L+G^4*M+G^5*N+G^6*O+G^7*P+G^8*Q+G^9*R;
	Temp1kpot=10^(Temp1kpot);
	return Temp1kpot
end

function read_Tstil(instr_ID)
	variable instr_ID
	setChannel_AVS_VISA(instr_ID,1)
	wait(30)
	variable Res0=readRes_AVS_VISA(instr_ID)
	variable Temp1kpot
	variable G=log(Res0);
	variable I=79362.66285435;
	variable J=-134213.208617999;
	variable K=101026.7304322;
	variable L=-44413.273683345;
	variable M=12564.321465816;
	variable N=-2371.588181102;
	variable O=298.641277814;
	variable P=-24.188904628;
	variable Q=1.143358358;
	variable R=-0.024026573;
	Temp1kpot=I+G*J+G^2*K+G^3*L+G^4*M+G^5*N+G^6*O+G^7*P+G^8*Q+G^9*R;
	Temp1kpot=10^(Temp1kpot);
	return Temp1kpot
end

function read_Tmc(instr_ID)
	variable instr_ID
	setChannel_AVS_VISA(instr_ID,2)
	wait(30)
	variable Res2=readRes_AVS_VISA(instr_ID)
	variable TempMC,S
	variable G=log(Res2);
	variable I=377.216752817996;
	variable J=-427.997233771579;
	variable K=196.257391896173;
	variable L=-45.0269209446177;
	variable M=5.15189309595643;
	variable N=-0.23487550283037;
	variable O=0;
	variable P=0;
	variable Q=0;
	variable R=0;
	S=I+G*J+G^2*K+G^3*L+G^4*M+G^5*N+G^6*O+G^7*P+G^8*Q+G^9*R;
	TempMC=10^S;
	return TempMC
end

//-------- Lakeshore -------------
function read_MCtemp(instr_ID)
	variable instr_ID
	return LSreadtemp(instr_ID, 6)
end
function/s log_Lakeshore(instr_ID)
	variable instr_ID
	return LSgetStatus(instr_ID)
end
