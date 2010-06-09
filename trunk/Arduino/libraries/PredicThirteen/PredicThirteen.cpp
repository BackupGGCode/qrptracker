/* 
 *  PredicThirteen.cpp
 *  
 *
 *  Created by Andrew Edmunds on 10-05-26.
 *  Copyright 2010 Andrew Edmunds. All rights reserved.
 *  Parts of this code are taken from PREDICT, an open source
 *  multi-user satellite tracking and orbital predition program.
 *  The algorithm used in this program is the SGP4 algorithm.
 *  
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
//#include <time.h>
#include "PredicThirteen.h"
//#include "WProgram.h"
#define DEBUG false
#define TEST false

int static Flags=0;
float static phase; 
float usecs, tsince;
long seconds;
uint64_t daynum, jul_utc, jul_epoch;

PredicThirteen::tle_t co57 = {10,
                 144.03510745,//ye, then time
		.00000045,//ndot/2 drag parameter
		00000.0,//n float dot/6 Drag Parameter
		0.000042, //bstar drag parameter
		98.7132,//inclination IN
		152.4464, //RA
		.000873,//eccentricity EC
		245.714100, //WP
		114.3119,//mean anomaly MA
		14.20500354,//mean motion MM
		3031, //Sat cat number
		8022, // element set number
		35761,//reveloution Number at Epoch
		"CO-57", "03031J"};//international Designation


void PredicThirteen::setElements(tle_t x){
	elements = x;	
}

float Degrees(float arg)
{
	/* Returns angle in degrees from argument in radians */
	return (arg/deg2rad);
}

void SetFlag(int flag)
{
	Flags|=flag;
}

void ClearFlag(int flag)
{
	Flags&=~flag;
}

float FMod2p(float x)
{
	/* Returns mod 2PI of argument */
	
	int i;
	float ret_val;
	
	ret_val=x;
	i=ret_val/twopi;
	ret_val-=i*twopi;
	
	if (ret_val<0.0)
	ret_val+=twopi;
	
	return ret_val;
}

float AcTan(float sinx, float cosx)
{
	/* Four-quadrant arctan function */
	
	if (cosx==0.0)
	{
		if (sinx>0.0)
		return (pio2);
		else
		return (x3pio2);
	}
	
	else
	{
		if (cosx>0.0)
		{
			if (sinx>0.0)
			return (atan(sinx/cosx));
			else
			return (twopi+atan(sinx/cosx));
		}
		
		else
		return (pi+atan(sinx/cosx));
	}
	return (pi+atan(sinx/cosx));
}

int isFlagClear(int flag)
{
	return (~Flags&flag);
}

float Frac64E6(uint64_t arg) {
  /* Returns fractional part of float represented as *E06 */
  long foo = arg / 1000000LL;
  long bar = arg - foo;
  return bar / 1000000.0;
}

float Frac(float arg)
{
	/* Returns fractional part of float argument */
	float ans = arg - (int)(arg);
	return ans;
}
float Modulus(float arg1, float arg2)
{
	/* Returns arg1 mod arg2 */

/*	int i;
	float ret_val;

	ret_val=arg1;
	i=ret_val/arg2;
	ret_val-=i*arg2;

	if (ret_val<0.0)
		ret_val+=arg2;

	return ret_val;*/
        double* intptr = new double;
        float frac = modf(arg1/arg2, intptr);
        return frac * arg2;

 //       int result = (int) (arg1/arg2);
 //       return arg1 - (float) result * arg2;
}


float ThetaG_JD(uint64_t jde6)
{
    
	float UT=0, TU=0, GMST=0;
        float jd;
        float thetag;
        uint64_t A, B, C, D;
        uint64_t CONST = 1000000LL;
        A = 24110.54841 * CONST;
        B = 8640184.812866 * CONST;
        C = 0.093104 * CONST;
        D = 6.2E-6 * CONST;
	jd= (long)(jde6 / CONST);
	uint64_t dummy = 714861;
	////printf("%llu divided by 1000000 = %f\n", dummy, dummy/1000000.0);
	uint64_t dumbval = 0LL+(uint64_t)jde6 - (uint64_t)jd*CONST;
	////printf("dumbval: %llu\n", dumbval);
        UT = dumbval/ (float)1000000.0;
	////printf("!!numerator: %llu\n", jde6 - (uint64_t)jd*CONST);
        ////printf("jd1: %f\n", jd);
	////printf("jdLL1: %llu\n", (uint64_t)jd* CONST);
	////printf("jde6: %llu\n", jde6);
	////printf("UT: %f\n",UT);
	TU=(jd-730550.5)/36525;
	////printf("%s: %f\n", "TU", TU);
	uint64_t GMSTLLU = A + TU*B + TU*TU*C - TU*TU*TU*D;
        GMST =( A + TU*B + TU*TU*C - TU*TU*TU*D) / CONST;
	////printf("gmstllu: %llu\n", GMSTLLU);
        ////printf("gmst1: %f\n", GMST);	
	uint64_t additives = secday*omega_E*UT*CONST;
	uint64_t secdayLLU = secday*CONST;
	uint64_t temp = GMSTLLU + additives;
	////printf("%llu mod %llu is %llu\n",GMSTLLU,secdayLLU,GMSTLLU % secdayLLU);
	////printf("secday: %f\nomega_E: %f\nUT: %f\nadditives: %f\n",secday,omega_E,UT, additives/1000000.0);
	////printf("temp: %llu\n", temp);
	////printf("secdayLLU: %llu\n", secdayLLU);
	GMST = (temp % secdayLLU) / 1000000.0;
	////printf("gmstMOD: %f\n", GMST);
//	GMST=Modulus(GMST+secday*omega_E*UT,secday);
        ////printf("gmst2: %f\n", GMST);
	thetag = (twopi*GMST/secday);

        ////printf("thetag: %f\n", thetag);
        return   thetag;
}
/*
 * This version not used, but here for reference
float ThetaG_JD(float jd)
{

        float UT=0, TU=0, GMST=0;
        float thetag;
        UT=Frac(jd);//+0.5);
        ////printf("UT: %f\n", UT);
        jd=jd-UT;
        ////printf("jd: %f\n", jd);
        TU=(jd-730550.5)/36525;
        ////printf("%s: %f\n", "TU", TU);
        GMST=24110.54841+TU*(8640184.812866+TU*(0.093104-TU*6.2E-6));
        GMST=Modulus(GMST+secday*omega_E*UT,secday);

        thetag = (twopi*GMST/secday);
        ////printf("thetag: %f\n", thetag);
        return thetag;
}
*/
float Sqr(float arg)
{
	/* Returns square of a float */
	return (arg*arg);
}
void Magnitude(PredicThirteen::vector_t *v)
{
	/* Calculates scalar magnitude of a vector_t argument */
	v->w=sqrt(Sqr(v->x)+Sqr(v->y)+Sqr(v->z));
}
void Scale_Vector(float k, PredicThirteen::vector_t *v)
{ 
	/* Multiplies the vector v1 by the scalar k */
	v->x*=k;
	v->y*=k;
	v->z*=k;
	Magnitude(v);
}
void Convert_Sat_State(PredicThirteen::vector_t *pos, PredicThirteen::vector_t *vel)
{
	/* Converts the satellite's position and velocity  */
	/* vectors from normalized values to km and km/sec */ 
	Scale_Vector(xkmper, pos);
	Scale_Vector(xkmper*minday/secday, vel);
}
void printfloat( float val){
  // prints val with number of decimal places determine by precision
  // precision is a number from 0 to 6 indicating the desired decimial places
  // example: //printfloat( 3.1415, 2); // //prints 3.14 (two decimal places)

    int precision = 7;
  Serial.print (int(val));  ////prints the int part
  if( precision > 0) {
    Serial.print("."); // //print the decimal point
    unsigned long frac;
    unsigned long mult = 1;
    byte padding = precision -1;
    while(precision--)
	 mult *=10;

    if(val >= 0)
	frac = (val - int(val)) * mult;
    else
	frac = (int(val)- val ) * mult;
    unsigned long frac1 = frac;
    while( frac1 /= 10 )
	padding--;
    while(  padding--)
	Serial.print("0");
    Serial.println(frac,DEC) ;

  }
}

void printVar(char *name, float var)
{
    Serial.print(name);
    Serial.print(": ");
    if((var - (int) var) == 0){
        Serial.print("(int) ");
        Serial.println(var);
    }
    else{
        Serial.print("(float) ");
        //Serial.println(var *1000000);
        printfloat(var);
    }
    ////printfloat(var);
}

void printTle(PredicThirteen::tle_t *tle)
{
    printVar("Epoch", tle->epoch_year * 1000 + tle->epoch_day);
    printVar("Drag",tle->xndt2o);
    printVar("Drag2",tle->xndd6o);
    printVar("Bstar",tle->bstar);
    printVar("Inclination",tle->xincl);
    printVar("RA",tle->xnodeo);
    printVar("EO",tle->eo);
    printVar("Omega",tle->omegao);
    printVar("Xmo",tle->xmo);
    printVar("Xno",tle->xno);
   ////printf("Epoch: %f\nDrag: %f\nDrag2: %f\nBstar: %f\nInclination: %f\n",
   //         tle->epoch,tle->xndt2o,tle->xndd6o,tle->bstar,tle->xincl);            
   ////printf("RA: %f\nEO: %f\nOmega: %f\nXmo: %f\nXno: %f\n",
   //         tle->xnodeo,tle->eo,tle->omegao,tle->xmo,tle->xno);
}

void select_ephemeris(PredicThirteen::tle_t *tle)
{
	/* Selects the apropriate ephemeris type to be used */
	/* for predictions according to the data in the TLE */
	/* It also processes values in the tle set so that  */
	/* they are apropriate for the sgp4/sdp4 routines   */

	float ao, xnodp, dd1, dd2, delo, temp, a1, del1, r1;

	/* Preprocess tle set */
	tle->xnodeo*=deg2rad;
	tle->omegao*=deg2rad;
	tle->xmo*=deg2rad;
	tle->xincl*=deg2rad;
	temp=twopi/minday/minday;
	tle->xno=tle->xno*temp*minday;
        //printVar("xno", tle->xno);
	tle->xndt2o*=temp;
	tle->xndd6o=tle->xndd6o*temp/minday;
	tle->bstar/=ae;

	/* Period > 225 minutes is deep space */
	dd1=(xke/tle->xno);
    //printVar("dd1", dd1);
	dd2=tothrd;
	a1=pow(dd1,dd2);
	r1=cos(tle->xincl);
	dd1=(1.0-tle->eo*tle->eo);
	temp=ck2*1.5f*(r1*r1*3.0-1.0)/pow(dd1,1.5);
	del1=temp/(a1*a1);
	ao=a1*(1.0-del1*(tothrd*.5+del1*(del1*1.654320987654321+1.0)));
	delo=temp/(ao*ao);
	xnodp=tle->xno/(delo+1.0);
	printVar("xnodp", xnodp);

	/* Select a deep-space/near-earth ephemeris */

	if (twopi/xnodp/minday>=0.15625)
		SetFlag(DEEP_SPACE_EPHEM_FLAG);
	else
		ClearFlag(DEEP_SPACE_EPHEM_FLAG);
}

void printVector(PredicThirteen::vector_t *vec){
	Serial.print("x: ");
	Serial.println(vec->x);
	Serial.print("y: ");
	Serial.println(vec->y);
	Serial.print("z: ");
	Serial.println(vec->z);
	Serial.print("w:");
	Serial.println(vec->w);
   ////printf("x: %f\ny: %f\nz: %f\nw: %f\n",vec->x, vec->y, vec->z, vec->w);
}


void SGP4(float tsince, PredicThirteen::tle_t * tle, PredicThirteen::vector_t * pos, PredicThirteen::vector_t * vel)
{
	/* This function is used to calculate the position and velocity */
	/* of near-earth (period < 225 minutes) satellites. tsince is   */
	/* time since epoch in minutes, tle is a pointer to a tle_t     */
	/* structure with Keplerian orbital elements and pos and vel    */
	/* are vector_t structures returning ECI satellite position and */ 
	/* velocity. Use Convert_Sat_State() to convert to km and km/s. */
	
	static float aodp, aycof, c1, c4, c5, cosio, d2, d3, d4, delmo,
	omgcof, eta, omgdot, sinio, xnodp, sinmo, t2cof, t3cof, t4cof,
	t5cof, x1mth2, x3thm1, x7thm1, xmcof, xmdot, xnodcf, xnodot, xlcof;
	
	float cosuk, sinuk, rfdotk, vx, vy, vz, ux, uy, uz, xmy, xmx, cosnok,
	sinnok, cosik, sinik, rdotk, xinck, xnodek, uk, rk, cos2u, sin2u,
	u, sinu, cosu, betal, rfdot, rdot, r, pl, elsq, esine, ecose, epw,
	cosepw, x1m5th, xhdot1, tfour, sinepw, capu, ayn, xlt, aynl, xll,
	axn, xn, beta, xl, e, a, tcube, delm, delomg, templ, tempe, tempa,
	xnode, tsq, xmp, omega, xnoddf, omgadf, xmdf, a1, a3ovk2, ao,
	betao, betao2, c1sq, c2, c3, coef, coef1, del1, delo, eeta, eosq,
	etasq, perigee, pinvsq, psisq, qoms24, s4, temp, temp1, temp2,
	temp3, temp4, temp5, temp6, theta2, theta4, tsi;
	
	int i;
        
        Serial.println("----------------------------------------");
        printTle(tle);
        
	
	/* Initialization */
	
	if (isFlagClear(SGP4_INITIALIZED_FLAG))
	{
		SetFlag(SGP4_INITIALIZED_FLAG);
		
		/* Recover original mean motion (xnodp) and   */
		/* semimajor axis (aodp) from input elements. */
		
		a1=pow(xke/tle->xno,tothrd);
		printVar("a1", a1);
		cosio=cos(tle->xincl);
                printVar("Tle->xincl", tle->xincl);
		theta2=cosio*cosio;
		x3thm1=3*theta2-1.0;
		printVar("theta2",theta2);
		printVar("cosio",cosio);
		eosq=tle->eo*tle->eo;
		betao2=1.0-eosq;
		betao=sqrt(betao2);
		del1=1.5*ck2*x3thm1/(a1*a1*betao*betao2);
		ao=a1*(1.0-del1*(0.5*tothrd+del1*(1.0+134.0/81.0*del1)));
		delo=1.5*ck2*x3thm1/(ao*ao*betao*betao2);
		xnodp=tle->xno/(1.0+delo);
		aodp=ao/(1.0-delo);

                printVar("aodp", aodp);
        Serial.println("----------------------------------------");        

		
		/* For perigee less than 220 kilometers, the "simple"     */
		/* flag is set and the equations are truncated to linear  */
		/* variation in sqrt a and quadratic variation in mean    */
		/* anomaly.  Also, the c3 term, the delta omega term, and */
		/* the delta m term are dropped.                          */
		
		if ((aodp*(1-tle->eo)/ae)<(220/xkmper+ae))
		SetFlag(SIMPLE_FLAG);
		
		else
		ClearFlag(SIMPLE_FLAG);
		
		/* For perigees below 156 km, the      */
		/* values of s and qoms2t are altered. */
		
		s4=s;
		qoms24=qoms2t;
		perigee=(aodp*(1-tle->eo)-ae)*xkmper;
		printVar("perigee", perigee);
		
			if (perigee<156.0)
			{
			if (perigee<=98.0)
			s4=20;
			else
			s4=perigee-78.0;
			
			qoms24=pow((120-s4)*ae/xkmper,4);
			s4=s4/xkmper+ae;
		}
        Serial.println("----------------------------------------");
        
		
		pinvsq=1/(aodp*aodp*betao2*betao2);
		tsi=1/(aodp-s4);
		eta=aodp*tle->eo*tsi;
		etasq=eta*eta;
                printVar("etasq",etasq);
		eeta=tle->eo*eta;
		psisq=fabs(1-etasq);
		coef=qoms24*pow(tsi,4);
		coef1=coef/pow(psisq,3.5);
		printVar("coef1",coef1);
		c2=coef1*xnodp*(aodp*(1+1.5*etasq+eeta*(4+etasq))+0.75*ck2*tsi/psisq*x3thm1*(8+3*etasq*(8+etasq)));
		printVar("xnodp", xnodp);
		printVar("etasq",etasq);
		printVar("eeta",eeta);
		printVar("ck2",ck2);
		printVar("tsi",tsi);
		printVar("psisq",psisq);
		printVar("x3thm1",x3thm1);
		printVar("c2",c2);
		c1=tle->bstar*c2;
		printVar("c1*1000000",c1*1000000);
                printVar("BSTAR: ", tle->bstar);
		sinio=sin(tle->xincl);
		a3ovk2=-xj3/ck2*pow(ae,3);
		c3=coef*tsi*a3ovk2*xnodp*ae*sinio/tle->eo;
		x1mth2=1-theta2;
		printVar("x1mth2", x1mth2);
        Serial.println("----------------------------------------");
        Serial.println("----------------------------------------");
        
		
		c4=2*xnodp*coef1*aodp*betao2*(eta*(2+0.5*etasq)+tle->eo*(0.5+2*etasq)-2*ck2*tsi/(aodp*psisq)*(-3*x3thm1*(1-2*eeta+etasq*(1.5-0.5*eeta))+0.75*x1mth2*(2*etasq-eeta*(1+etasq))*cos(2*tle->omegao)));
		c5=2*coef1*aodp*betao2*(1+2.75*(etasq+eeta)+eeta*etasq);
		
		theta4=theta2*theta2;
		temp1=3*ck2*pinvsq*xnodp;
		temp2=temp1*ck2*pinvsq;
		temp3=1.25*ck4*pinvsq*pinvsq*xnodp;
		xmdot=xnodp+0.5*temp1*betao*x3thm1+0.0625*temp2*betao*(13-78*theta2+137*theta4);
		x1m5th=1-5*theta2;
		omgdot=-0.5*temp1*x1m5th+0.0625*temp2*(7-114*theta2+395*theta4)+temp3*(3-36*theta2+49*theta4);
		xhdot1=-temp1*cosio;
		xnodot=xhdot1+(0.5*temp2*(4-19*theta2)+2*temp3*(3-7*theta2))*cosio;
		omgcof=tle->bstar*c3*cos(tle->omegao);
		xmcof=-tothrd*coef*tle->bstar*ae/eeta;
		xnodcf=3.5*betao2*xhdot1*c1;
		t2cof=1.5*c1;
                printVar("t2cof*1000000", t2cof*1000000);
		xlcof=0.125*a3ovk2*sinio*(3+5*cosio)/(1+cosio);
		aycof=0.25*a3ovk2*sinio;
		delmo=pow(1+eta*cos(tle->xmo),3);
		sinmo=sin(tle->xmo);
		x7thm1=7*theta2-1;
		printVar("x7thm1", x7thm1);
		
		if (isFlagClear(SIMPLE_FLAG))
		{
			c1sq=c1*c1;
			d2=4*aodp*tsi*c1sq;
			temp=d2*tsi*c1/3;
			d3=(17*aodp+s4)*temp;
			d4=0.5*temp*aodp*tsi*(221*aodp+31*s4)*c1;
			t3cof=d2+2*c1sq;
			t4cof=0.25*(3*d3+c1*(12*d2+10*c1sq));
			t5cof=0.2*(3*d4+12*c1*d3+6*d2*d2+15*c1sq*(2*d2+c1sq));
		}
	}
	
	/* Update for secular gravity and atmospheric drag. */
	xmdf=tle->xmo+xmdot*tsince;
	omgadf=tle->omegao+omgdot*tsince;
	xnoddf=tle->xnodeo+xnodot*tsince;
	omega=omgadf;
	xmp=xmdf;
	tsq=tsince*tsince;
        printVar("tsince*1000000", tsince*1000000);
	printVar("tsq", tsq);        

	xnode=xnoddf+xnodcf*tsq;
	tempa=1-c1*tsince;
	tempe=tle->bstar*c4*tsince;
	templ=t2cof*tsq;
	printVar("templ", templ);

    
	if (isFlagClear(SIMPLE_FLAG))
	{
		delomg=omgcof*tsince;
		delm=xmcof*(pow(1+eta*cos(xmdf),3)-delmo);
		temp=delomg+delm;
		xmp=xmdf+temp;
		omega=omgadf-temp;
		tcube=tsq*tsince;
		tfour=tsince*tcube;
		tempa=tempa-d2*tsq-d3*tcube-d4*tfour;
		tempe=tempe+tle->bstar*c5*(sin(xmp)-sinmo);
		templ=templ+t3cof*tcube+tfour*(t4cof+tsince*t5cof);
                printVar("templ", templ);
	}
	
	a=aodp*pow(tempa,2);
	e=tle->eo-tempe;
	xl=xmp+omega+xnode+xnodp*templ;
	beta=sqrt(1-e*e);
	xn=xke/pow(a,1.5);
	
	/* Long period periodics */
	axn=e*cos(omega);
	temp=1/(a*beta*beta);
	xll=temp*xlcof*axn;
	aynl=temp*aycof;
	xlt=xl+xll;
	ayn=e*sin(omega)+aynl;
	
	/* Solve Kepler's Equation */
	capu=FMod2p(xlt-xnode);
	temp2=capu;
	i=0;
	
	do
	{
		sinepw=sin(temp2);
		cosepw=cos(temp2);
		temp3=axn*sinepw;
		temp4=ayn*cosepw;
		temp5=axn*cosepw;
		temp6=ayn*sinepw;
		epw=(capu-temp4+temp3-temp2)/(1-temp5-temp6)+temp2;
		
		if (fabs(epw-temp2)<= e6a)
		break;
		
		temp2=epw;
		
	} while (i++<10);
	
	/* Short p2eriod preliminary quantities */
	ecose=temp5+temp6;
	esine=temp3-temp4;
	elsq=axn*axn+ayn*ayn;
	temp=1-elsq;
	pl=a*temp;
	r=a*(1-ecose);
	temp1=1/r;
	rdot=xke*sqrt(a)*esine*temp1;
	rfdot=xke*sqrt(pl)*temp1;
	temp2=a*temp1;
	betal=sqrt(temp);
	temp3=1/(1+betal);
	cosu=temp2*(cosepw-axn+ayn*esine*temp3);
	sinu=temp2*(sinepw-ayn-axn*esine*temp3);
	u=AcTan(sinu,cosu);
	sin2u=2*sinu*cosu;
	cos2u=2*cosu*cosu-1;
	temp=1/pl;
	temp1=ck2*temp;
	temp2=temp1*temp;
	
	/* Update for short periodics */
	rk=r*(1-1.5*temp2*betal*x3thm1)+0.5*temp1*x1mth2*cos2u;
	uk=u-0.25*temp2*x7thm1*sin2u;
	xnodek=xnode+1.5*temp2*cosio*sin2u;
	xinck=tle->xincl+1.5*temp2*cosio*sinio*cos2u;
	rdotk=rdot-xn*temp1*x1mth2*sin2u;
	rfdotk=rfdot+xn*temp1*(x1mth2*cos2u+1.5*x3thm1);
	
	/* Orientation vectors */
	sinuk=sin(uk);
	cosuk=cos(uk);
	sinik=sin(xinck);
	cosik=cos(xinck);
	sinnok=sin(xnodek);
	cosnok=cos(xnodek);
	xmx=-sinnok*cosik;
	xmy=cosnok*cosik;
	ux=xmx*sinuk+cosnok*cosuk;
	uy=xmy*sinuk+sinnok*cosuk;
	uz=sinik*sinuk;
	vx=xmx*cosuk-cosnok*sinuk;
	vy=xmy*cosuk-sinnok*sinuk;
	vz=sinik*cosuk;
	
	/* Position and velocity */
	pos->x=rk*ux;
	pos->y=rk*uy;
	pos->z=rk*uz;
	vel->x=rdotk*ux+rfdotk*vx;
	vel->y=rdotk*uy+rfdotk*vy;
	vel->z=rdotk*uz+rfdotk*vz;
        
        Serial.println("----------------------------------------");
        Serial.print("Position: ");
        printVector(pos);
        Serial.print("Velocity; ");
        printVector(vel);
        //printf("1st Position: (%f,%f,%f,%f)\n", pos->x,pos->y,pos->z,pos->w);
        //printf("1st Velocity: (%f,%f,%f,%f)\n)", vel->x,vel->y,vel->z,vel->w);        
	
	/* Phase in radians */
	phase=xlt-xnode-omgadf+twopi;
    
	if (phase<0.0)
	phase+=twopi;
	
	phase=FMod2p(phase);
}

void Calculate_LatLonAlt(uint64_t time, PredicThirteen::vector_t *pos,  PredicThirteen::geodetic_t *geodetic)
{
	/* Procedure Calculate_LatLonAlt will calculate the geodetic  */
	/* position of an object given its ECI position pos and time. */
	/* It is intended to be used to determine the ground track of */
	/* a satellite.  The calculations  assume the earth to be an  */
	/* oblate spheroid as defined in WGS '72.                     */

	/* Reference:  The 1992 Astronomical Almanac, page K12. */

	float r, e2, phi, c;

	geodetic->theta=AcTan(pos->y,pos->x); /* radians */
	geodetic->lon=FMod2p(geodetic->theta-ThetaG_JD(time)); /* radians */
	r=sqrt(Sqr(pos->x)+Sqr(pos->y));
        //printVar("r", r);
	e2=f*(2-f);
	geodetic->lat=AcTan(pos->z,r); /* radians */

	do
	{
		phi=geodetic->lat;
		c=1/sqrt(1-e2*Sqr(sin(phi)));
		geodetic->lat=AcTan(pos->z+xkmper*c*e2*sin(phi),r);

	} while (fabs(geodetic->lat-phi)>=1E-10);

	geodetic->alt=r/cos(geodetic->lat)-xkmper*c; /* kilometers */

	if (geodetic->lat>pio2)
		geodetic->lat-=twopi;
}



void printGeo(PredicThirteen::geodetic_t *geo){
  		Serial.print("lat: ");
		Serial.println(Degrees(geo->lat));
		Serial.print("lon: ");
		Serial.println(Degrees(geo->lon));
		Serial.print("alt: ");
		Serial.println(geo->alt);
		Serial.print("theta: ");
		Serial.println(geo->theta);
	   ////printf("lat: %f\nlon: %f\nalt: %f\ntheta: %f\n",Degrees(geo->lat), 360 -Degrees(geo->lon), geo->alt, geo->theta);
	}

uint64_t Julian_Date_of_Year(float year)
{
        /* The function Julian_Date_of_Year calculates the Julian Date  */
        /* of Day 0.0 of {year}. This function is used to calculate the */
        /* Julian Date of any date by using Julian_Date_of_Year, DOY,   */
        /* and Fraction_of_Day. */

        /* Astronomical Formulae for Calculators, Jean Meeus, */
        /* pages 23-25. Calculate Julian Date of 0.0 Jan year */
        uint64_t out = 0LL;
        long A, B, i;
        float jdoy;
                ////printf("Year into JDoY: %f\n", year);
        year=year-1;
        i=year/100;
        ////printVar("i", i);
        A=i;
        i=A/4;
        B=2-A+i;
        ////printVar("B", B);
        i=365.25*year;
        i+=30.6001*14;
        ////printVar("i", i);
       // //printVar("B", B);
        out += i;
        out += B;
        ////printf("out: %llu", out);
        return out;
}
/*
uint64_t  Julian_Date_of_Year(float year)
{
	long A, B, i;
	float jdoy;
        ////printf("Year into JDoY: %f\n", year);
	year=year-1;
	i=year/100;
	A=i;
	i=A/4;
	B=2-A+i;
	i=365.25*year;
	i+=30.6001*14;
	jdoy=i+1720994.5+B;

	return (i+B) * 1000000;//jdoy;
}
*/
uint64_t Julian_Date_of_Epoch(float epoch_year, float epoch_day)
{ 
	/* The function Julian_Date_of_Epoch returns the Julian Date of     */
	/* an epoch specified in the format used in the NORAD two-line      */
	/* element sets. It has been modified to support dates beyond       */
	/* the year 1999 assuming that two-digit years in the range 00-56   */
	/* correspond to 2000-2056. Until the two-line element set format   */
	/* is changed, it is only valid for dates through 2056 December 31. */

//	float year, day;

	/* Modification to support Y2K */
	/* Valid 1957 through 2056     */

//	day=modf(epoch*1E-3, &year)*1E3;

//	if (year<57)
//		year=year+2000;
//	else
//		year=year+1900;

//	return (Julian_Date_of_Year(year)+day);
        uint64_t jdy = Julian_Date_of_Year(epoch_year + 2000);
        ////printf("jdy: %llu\n", jdy);
        uint64_t yearPart = Julian_Date_of_Year(epoch_year + 2000)*1000000LL;
        uint64_t dayPart = epoch_day*1000000LL;
        ////printf("yearPart: %llu\ndayPart: %llu\n",yearPart,dayPart);
        return yearPart + dayPart;
	//return (Julian_Date_of_Year(epoch_year + 2000)*1000000LL + epoch_day*1000000LL);
}
/* Sets the time to specified time. Format is standard Unix time, seconds    */
/*   from epoch plus microseconds.                                           */
void PredicThirteen::setTime(long sec)
{
    ////printf("curtime: %f\n", curtime);
    seconds =  sec; //utams;
    //orig. daynum *E6
    daynum = seconds *10000/864LL - (3651000000LL);
    Serial.print("seconds: ");
    Serial.println(seconds);


}

void PredicThirteen::calc(PredicThirteen::tle_t t){
        printTle(&t);
        Serial.println("----------------------------------------");
        PredicThirteen::vector_t zero_vector={0,0,0,0};
        PredicThirteen::vector_t pos = zero_vector;
        PredicThirteen::vector_t vel = zero_vector;
	PredicThirteen::geodetic_t geo = {0,0,0,0};

        jul_utc = daynum +723244000000LL;
        jul_epoch=Julian_Date_of_Epoch(t.epoch_year, t.epoch_day);
        ////printf("jul_utc: %llu\njul_epoch: %llu\n", jul_utc, jul_epoch);
        printVar("daynum", daynum);
        printVar("jul_utc",jul_utc);
        printVar("jul_epoch",jul_epoch);
        tsince =   ((jul_utc - jul_epoch)/1000000.0) * minday;
         
        ////printf("TimeSince: %f\nUnix: %f\n", tsince, seconds);
        ////printf("TimeLatLong: %llu\n", jul_utc);

        select_ephemeris(&t);
    
	SGP4(tsince, &t, &pos, &vel);
	Convert_Sat_State(&pos, &vel);   
	Magnitude(&vel);        
        //printVar("jul_utc", jul_utc);
	Calculate_LatLonAlt(jul_utc, &pos, &geo);
        ////printf("Position\n");
        printVector(&pos);
        ////printf("Velocity:\n");
        printVector(&vel);
        ////printf("Geo:\n");
        printGeo(&geo);
	}
	

/*int main(){
    setTime(0);
    calc(co57);
	//////printf("Answer: %f\n", ThetaG_JD(2455343.50000));
	//float *temp = new float;
	//modf(444.34, temp);
	//////printf("Done");

}*/
