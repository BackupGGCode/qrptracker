/*
 *  pred13t.cpp
 *  
 *
 *  Created by Andrew Edmunds on 10-05-26.
 *  Copyright 2010 Andrew Edmunds. All rights reserved.
 *  Parts of this code are taken from PREDICT, an open source
 *  multi-user satellite tracking and orbital predition program.
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

#include "Pred13t.h"
//#include "WProgram.h"
#define DEBUG false
#define TEST false

Pred13t::tle_t co57 = {10144.03510745,//ye, then time
		.00000045,//ndot/2 drag parameter
		00000.0,//n double dot/6 Drag Parameter
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
		"CO-57", "03031J"};//international Designation}

void Pred13t::setElements(tle_t x){
	elements = x;	
}

double Degrees(double arg)
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

double FMod2p(double x)
{
	/* Returns mod 2PI of argument */
	
	int i;
	double ret_val;
	
	ret_val=x;
	i=ret_val/twopi;
	ret_val-=i*twopi;
	
	if (ret_val<0.0)
	ret_val+=twopi;
	
	return ret_val;
}

double AcTan(double sinx, double cosx)
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

double Frac(double arg)
{
	/* Returns fractional part of double argument */
	double ans = arg - (int)(arg);
	return ans;
}
double Modulus(double arg1, double arg2)
{
	/* Returns arg1 mod arg2 */

	int i;
	double ret_val;

	ret_val=arg1;
	i=ret_val/arg2;
	ret_val-=i*arg2;

	if (ret_val<0.0)
		ret_val+=arg2;

	return ret_val;
}

double ThetaG_JD(double jd)
{
	/* Reference:  The 1992 Astronomical Almanac, page B6. */

	double UT=0, TU=0, GMST=0;
	
	UT=Frac(jd+0.5);
	jd=jd-UT;
	TU=(jd-2451545.0)/36525;
	GMST=24110.54841+TU*(8640184.812866+TU*(0.093104-TU*6.2E-6));
	GMST=Modulus(GMST+secday*omega_E*UT,secday);

	return (twopi*GMST/secday);
}
double Sqr(double arg)
{
	/* Returns square of a double */
	return (arg*arg);
}
void Magnitude(Pred13t::vector_t *v)
{
	/* Calculates scalar magnitude of a vector_t argument */
	v->w=sqrt(Sqr(v->x)+Sqr(v->y)+Sqr(v->z));
}
void Scale_Vector(double k, Pred13t::vector_t *v)
{ 
	/* Multiplies the vector v1 by the scalar k */
	v->x*=k;
	v->y*=k;
	v->z*=k;
	Magnitude(v);
}
void Convert_Sat_State(Pred13t::vector_t *pos, Pred13t::vector_t *vel)
{
	/* Converts the satellite's position and velocity  */
	/* vectors from normalized values to km and km/sec */ 
	Scale_Vector(xkmper, pos);
	Scale_Vector(xkmper*minday/secday, vel);
}

void printTle(Pred13t::tle_t *tle)
{
   //printf("Epoch: %f\nDrag: %f\nDrag2: %f\nBstar: %f\nInclination: %f\n",
   //         tle->epoch,tle->xndt2o,tle->xndd6o,tle->bstar,tle->xincl);            
   //printf("RA: %f\nEO: %f\nOmega: %f\nXmo: %f\nXno: %f\n",
   //         tle->xnodeo,tle->eo,tle->omegao,tle->xmo,tle->xno);
}

void select_ephemeris(Pred13t::tle_t *tle)
{
	/* Selects the apropriate ephemeris type to be used */
	/* for predictions according to the data in the TLE */
	/* It also processes values in the tle set so that  */
	/* they are apropriate for the sgp4/sdp4 routines   */

	double ao, xnodp, dd1, dd2, delo, temp, a1, del1, r1;

	/* Preprocess tle set */
	tle->xnodeo*=deg2rad;
	tle->omegao*=deg2rad;
	tle->xmo*=deg2rad;
	tle->xincl*=deg2rad;
	temp=twopi/minday/minday;
	tle->xno=tle->xno*temp*minday;
	tle->xndt2o*=temp;
	tle->xndd6o=tle->xndd6o*temp/minday;
	tle->bstar/=ae;

	/* Period > 225 minutes is deep space */
	dd1=(xke/tle->xno);
	dd2=tothrd;
	a1=pow(dd1,dd2);
	r1=cos(tle->xincl);
	dd1=(1.0-tle->eo*tle->eo);
	temp=ck2*1.5f*(r1*r1*3.0-1.0)/pow(dd1,1.5);
	del1=temp/(a1*a1);
	ao=a1*(1.0-del1*(tothrd*.5+del1*(del1*1.654320987654321+1.0)));
	delo=temp/(ao*ao);
	xnodp=tle->xno/(delo+1.0);

	/* Select a deep-space/near-earth ephemeris */

	if (twopi/xnodp/minday>=0.15625)
		SetFlag(DEEP_SPACE_EPHEM_FLAG);
	else
		ClearFlag(DEEP_SPACE_EPHEM_FLAG);
}


void SGP4(double tsince, Pred13t::tle_t * tle, Pred13t::vector_t * pos, Pred13t::vector_t * vel)
{
	/* This function is used to calculate the position and velocity */
	/* of near-earth (period < 225 minutes) satellites. tsince is   */
	/* time since epoch in minutes, tle is a pointer to a tle_t     */
	/* structure with Keplerian orbital elements and pos and vel    */
	/* are vector_t structures returning ECI satellite position and */ 
	/* velocity. Use Convert_Sat_State() to convert to km and km/s. */
	
	static double aodp, aycof, c1, c4, c5, cosio, d2, d3, d4, delmo,
	omgcof, eta, omgdot, sinio, xnodp, sinmo, t2cof, t3cof, t4cof,
	t5cof, x1mth2, x3thm1, x7thm1, xmcof, xmdot, xnodcf, xnodot, xlcof;
	
	double cosuk, sinuk, rfdotk, vx, vy, vz, ux, uy, uz, xmy, xmx, cosnok,
	sinnok, cosik, sinik, rdotk, xinck, xnodek, uk, rk, cos2u, sin2u,
	u, sinu, cosu, betal, rfdot, rdot, r, pl, elsq, esine, ecose, epw,
	cosepw, x1m5th, xhdot1, tfour, sinepw, capu, ayn, xlt, aynl, xll,
	axn, xn, beta, xl, e, a, tcube, delm, delomg, templ, tempe, tempa,
	xnode, tsq, xmp, omega, xnoddf, omgadf, xmdf, a1, a3ovk2, ao,
	betao, betao2, c1sq, c2, c3, coef, coef1, del1, delo, eeta, eosq,
	etasq, perigee, pinvsq, psisq, qoms24, s4, temp, temp1, temp2,
	temp3, temp4, temp5, temp6, theta2, theta4, tsi;
	
	int i;

        //printTle(tle);
        
	
	/* Initialization */
	
	if (isFlagClear(SGP4_INITIALIZED_FLAG))
	{
		SetFlag(SGP4_INITIALIZED_FLAG);
		
		/* Recover original mean motion (xnodp) and   */
		/* semimajor axis (aodp) from input elements. */
		
		a1=pow(xke/tle->xno,tothrd);
		cosio=cos(tle->xincl);
		theta2=cosio*cosio;
		x3thm1=3*theta2-1.0;
		eosq=tle->eo*tle->eo;
		betao2=1.0-eosq;
		betao=sqrt(betao2);
		del1=1.5*ck2*x3thm1/(a1*a1*betao*betao2);
		ao=a1*(1.0-del1*(0.5*tothrd+del1*(1.0+134.0/81.0*del1)));
		delo=1.5*ck2*x3thm1/(ao*ao*betao*betao2);
		xnodp=tle->xno/(1.0+delo);
		aodp=ao/(1.0-delo);
		
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
		
		if (perigee<156.0)
		{
			if (perigee<=98.0)
			s4=20;
			else
			s4=perigee-78.0;
			
			qoms24=pow((120-s4)*ae/xkmper,4);
			s4=s4/xkmper+ae;
		}
		
		pinvsq=1/(aodp*aodp*betao2*betao2);
		tsi=1/(aodp-s4);
		eta=aodp*tle->eo*tsi;
		etasq=eta*eta;
		eeta=tle->eo*eta;
		psisq=fabs(1-etasq);
		coef=qoms24*pow(tsi,4);
		coef1=coef/pow(psisq,3.5);
		c2=coef1*xnodp*(aodp*(1+1.5*etasq+eeta*(4+etasq))+0.75*ck2*tsi/psisq*x3thm1*(8+3*etasq*(8+etasq)));
		c1=tle->bstar*c2;
		sinio=sin(tle->xincl);
		a3ovk2=-xj3/ck2*pow(ae,3);
		c3=coef*tsi*a3ovk2*xnodp*ae*sinio/tle->eo;
		x1mth2=1-theta2;
		
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
		xlcof=0.125*a3ovk2*sinio*(3+5*cosio)/(1+cosio);
		aycof=0.25*a3ovk2*sinio;
		delmo=pow(1+eta*cos(tle->xmo),3);
		sinmo=sin(tle->xmo);
		x7thm1=7*theta2-1;
		
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
	xnode=xnoddf+xnodcf*tsq;
	tempa=1-c1*tsince;
	tempe=tle->bstar*c4*tsince;
	templ=t2cof*tsq;
    
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

        //printf("1st Position: (%f,%f,%f,%f)\n", pos->x,pos->y,pos->z,pos->w);
        //printf("1st Velocity: (%f,%f,%f,%f)\n)", vel->x,vel->y,vel->z,vel->w);        
	
	/* Phase in radians */
	phase=xlt-xnode-omgadf+twopi;
    
	if (phase<0.0)
	phase+=twopi;
	
	phase=FMod2p(phase);
}

void Calculate_LatLonAlt(double time, Pred13t::vector_t *pos,  Pred13t::geodetic_t *geodetic)
{
	/* Procedure Calculate_LatLonAlt will calculate the geodetic  */
	/* position of an object given its ECI position pos and time. */
	/* It is intended to be used to determine the ground track of */
	/* a satellite.  The calculations  assume the earth to be an  */
	/* oblate spheroid as defined in WGS '72.                     */

	/* Reference:  The 1992 Astronomical Almanac, page K12. */

	double r, e2, phi, c;

	geodetic->theta=AcTan(pos->y,pos->x); /* radians */
	geodetic->lon=FMod2p(geodetic->theta-ThetaG_JD(time)); /* radians */
	r=sqrt(Sqr(pos->x)+Sqr(pos->y));
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

void printVector(Pred13t::vector_t *vec){
   //printf("x: %f\ny: %f\nz: %f\nw: %f\n",vec->x, vec->y, vec->z, vec->w);
}

void printGeo(Pred13t::geodetic_t *geo){
   //printf("lat: %f\nlon: %f\nalt: %f\ntheta: %f\n",Degrees(geo->lat), 360 -Degrees(geo->lon), geo->alt, geo->theta);
}

double Julian_Date_of_Year(double year)
{
	/* The function Julian_Date_of_Year calculates the Julian Date  */
	/* of Day 0.0 of {year}. This function is used to calculate the */
	/* Julian Date of any date by using Julian_Date_of_Year, DOY,   */
	/* and Fraction_of_Day. */

	/* Astronomical Formulae for Calculators, Jean Meeus, */
	/* pages 23-25. Calculate Julian Date of 0.0 Jan year */

	long A, B, i;
	double jdoy;

	year=year-1;
	i=year/100;
	A=i;
	i=A/4;
	B=2-A+i;
	i=365.25*year;
	i+=30.6001*14;
	jdoy=i+1720994.5+B;

	return jdoy;
}

double Julian_Date_of_Epoch(double epoch)
{ 
	/* The function Julian_Date_of_Epoch returns the Julian Date of     */
	/* an epoch specified in the format used in the NORAD two-line      */
	/* element sets. It has been modified to support dates beyond       */
	/* the year 1999 assuming that two-digit years in the range 00-56   */
	/* correspond to 2000-2056. Until the two-line element set format   */
	/* is changed, it is only valid for dates through 2056 December 31. */

	double year, day;

	/* Modification to support Y2K */
	/* Valid 1957 through 2056     */

	day=modf(epoch*1E-3, &year)*1E3;

	if (year<57)
		year=year+2000;
	else
		year=year+1900;

	return (Julian_Date_of_Year(year)+day);
}
/* Sets the time to specified time. Format is standard Unix time, seconds    */
/*   from epoch plus microseconds.                                           */
void setTime(double utams)
{
    seconds = utams;
    if (utams <= 0)
    {
        //struct timeval tptr;

        //gettimeofday(&tptr, NULL);

        //usecs = 0.000001*(double)tptr.tv_usec;
        //seconds = usecs + (double) tptr.tv_sec;
        utams = 1234567890.0;
    }
    daynum = seconds/86400.0 - 3651.0;



}

void calc(Pred13t::tle_t t){
        Pred13t::vector_t zero_vector={0,0,0,0};
        Pred13t::vector_t pos = zero_vector;
        Pred13t::vector_t vel = zero_vector;
	Pred13t::geodetic_t geo = {0,0,0,0};

        jul_utc = daynum+2444238.5;
        jul_epoch=Julian_Date_of_Epoch(t.epoch);
        t_since = (jul_utc - jul_epoch) * minday;

        //printf("TimeSince: %f\nUnix: %f\n", tsince, seconds - usecs );
        //printf("TimeLatLong: %f\n", jul_utc);

        select_ephemeris(&t);
    
	SGP4(t_since, &t, &pos, &vel);
	Convert_Sat_State(&pos, &vel);   
	Magnitude(&vel);        
	Calculate_LatLonAlt(jul_utc, &pos, &geo);
        SLAT = Degrees(geo.lat);
        SLON= 360 - Degrees(geo.lon);
        //printf("Position\n");
        //printVector(&pos);
        //printf("Velocity:\n");
        //printVector(&vel);
        //printf("Geo:\n");
        //printGeo(&geo);
	}
	

int main(){
    setTime(0);
    calc(co57);
	//printf("Answer: %f\n", ThetaG_JD(2455343.50000));
	//double *temp = new double;
	//modf(444.34, temp);
	//printf("Done");

}
