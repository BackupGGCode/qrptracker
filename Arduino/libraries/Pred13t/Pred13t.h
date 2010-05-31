/*
 *  pred13t.h
 *  
 *
 *  Created by Andrew Edmunds on 10-05-26.
 *  Copyright 2010 Andrew Edmunds. All rights reserved.
 *  
 *
 */

//#include <math.h>
//#include <stdio.h>
//#include <sys/time.h>
#include "WProgram.h"

#define xke		7.43669161E-2
#define tothrd		6.6666666666666666E-1	/* 2/3 */
#define ck2		5.413079E-4
#define ae		1.0
#define xkmper		6.378137E3		/* WGS 84 Earth radius km */
#define SIMPLE_FLAG            0x000020
#define twopi		6.28318530717958623	/* 2*Pi  */
#define s		1.012229
#define qoms2t		1.880279E-09
#define xj3		-2.53881E-6		/* J3 Harmonic (WGS '72) */   
#define ck4		6.209887E-7
#define pio2		1.57079632679489656	/* Pi/2 */
#define x3pio2		4.71238898038468967	/* 3*Pi/2 */
#define pi		3.14159265358979323846	/* Pi */
#define e6a		1.0E-6
#define secday		8.6400E4	/* Seconds per day */
#define omega_E		1.00273790934	/* Earth rotations/siderial day */
#define f		3.35281066474748E-3	/* Flattening factor */
#define SGP4_INITIALIZED_FLAG  0x000002
#define epoch_start     2440587.50000
#define minday		1.44E3			/* Minutes per day */
#define deg2rad		1.745329251994330E-2	/* Degrees to radians */
#define DEEP_SPACE_EPHEM_FLAG  0x000040








int static Flags=0;
double static phase; 
double static seconds, daynum, jul_utc, jul_epoch, t_since;
double static AZ, EL, SLAT, SLON, rxOUT, txOUT;


class Pred13t {
	public:
	
	typedef struct {
		double  epoch,//ye, then time
		xndt2o,//ndot/2 drag parameter
		xndd6o,//n double dot/6 Drag Parameter
		bstar, //bstar drag parameter
		xincl,//inclination IN
		xnodeo, //RA
		eo,//eccentricity EC
		omegao, //WP
		xmo,//mean anomaly MA
		xno;//mean motion MM
		int	   catnr, //Sat cat number
		elset, // element set number
		revnum;//reveloution Number at Epoch
		char	   sat_name[25], idesg[9];//international Designation
	}tle_t;
	/* Geodetic position structure used by SGP4/SDP4 code. */
	
	typedef struct	{
		double lat, lon, alt, theta;
	}  geodetic_t;
	typedef struct {
		char line1[70];
		char line2[70];
		char name[25];
		long catnum;
		long setnum;
		char designator[10];
		int year;
		double refepoch;
		double incl;
		double raan;
		double eccn;
		double argper;
		double meanan;
		double meanmo;
		double drag;
		double nddot6;
		double bstar;
		long orbitnum;
	}sat;
	/* General three-dimensional vector structure used by SGP4/SDP4 code. */
	
	typedef struct	{
		double x, y, z, w;
	}  vector_t;
	
	
	Pred13t::tle_t elements;
//	double rad(double deg);
//	double deg(double rad);
//	double FNatn(double y, double x);
//	double FNday(int year, int month, int day);
//	double myFNday(int year, int month, int day, int uh, int um, int us);
//	double getElement(char *gstr, int gstart, int gstop);
//	void readElements(char *satellite);
//	void initSat(void);
//	void satvec(void);
//	void rangevec(void);
//	void sunvec(void);
//	void calculate(void);
//	void footprintOctagon(float *octagon, float SLATin, float SLONin, float REin, float RAin);
//	void printdata(void);
//	void setFrequency(unsigned long rx_frequency, unsigned long tx_frequency);
//	void setLocation(double lon, double lat, int height);
//	void setTime(int yearIn, int monthIn, int mDayIn, int hourIn, int minIn, int secIn);
	
	void setElements(Pred13t::tle_t);
	int isFlagClear(int flag);
	void SetFlag(int flag);
	void ClearFlag(int flag);
	double FMod2p(double x);
	void SGP4(double tsince, Pred13t::tle_t * tle, Pred13t::vector_t * pos, Pred13t::vector_t * vel);
        void setTime(double unixTimeAndMicroseconds);
        void calc(Pred13t::tle_t tle);

	
	
//	int getDoppler(unsigned long freq);
//	int getDoppler64(unsigned long freq);
	
	//double rx, tx;
//	double observer_lon;
//	double observer_lat;
//	int observer_height;
//	unsigned long rxOutLong;
//	unsigned long txOutLong;
//	unsigned long rxFrequencyLong;
//	unsigned long txFrequencyLong;
//	float dopplerFactor;
//	const static double   YM = 365.25;     /* Days in a year                     */
//	double   EL;                           /* Elevation                          */
//	double   TN;                           /*                                    */
//	
//	double   E;
//	double   N;
//	double   AZ;
//	double   SLON;
//	double   SLAT;
//	double   RR;
//	
//	double   CL;
//	double   CS;
//	double   SL;
//	double   CO;
//	double   SO;
//	double   RE;
//	double   FL;
//	double   RP;
//	double   XX;
//	double   ZZ;
//	double   D;
//	double   R;
//	double   Rx;
//	double   Ry;
//	double   Rz;
//	double   Ex;
//	double   Ey;
//	double   Ez;
//	double   Ny;
//	double   Nx;
//	double   Nz;
//	double   Ox;
//	double   Oy;
//	double   Oz;
//	double   U;
//	double   Ux;
//	double   Uy;
//	double   Uz;
//	const static double   YT = 365.2421970;
//	double   WW;
//	double   WE;
//	double   W0;
//	double   VOx;
//	double   VOy;
//	double   VOz;
//	double   DE;
//	double   GM;
//	double   J2;
//	double   N0;
//	double   A0;
//	double   b0;
//	double   SI;
//	double   CI;
//	double   PC;
//	double   QD;
//	double   WD;
//	double   DC;
//	double   YG;
//	double   G0;
//	double   MAS0;
//	double   MASD;
//	double   INS;
//	double   CNS;
//	double   SNS;
//	double   EQC1;
//	double   EQC2;
//	double   TEG;
//	double   GHAE;
//	double   MRSE;
//	double   MASE;
//	double   ax;
//	double   ay;
//	double   az;
//	int      OLDRN;
//	
//	double   T;
//	double   DT;
//	double   KD;
//	double   KDP;
//	double   M;
//	int      DR;
//	long     RN;
//	double   EA;
//	double   C;
//	double   S;
//	double   DNOM;
//	double   A;
//	double   B;
//	double   RS;
//	double   Sx;
//	double   Sy;
//	//double   Sz;
//	double   Vx;
//	double   Vy;
//	double   Vz;
//	double   AP;
//	double   CWw;
//	double   SW;
//	double   RAAN;
//	double   CQ;
//	double   SQ;
//	double   CXx;
//	double   CXy;
//	double   CXz;
//	double   CYx;
//	double   CYy;
//	double   CYz;
//	double   CZx;
//	double   CZy;
//	double   CZz;
//	double   SATx;
//	double   SATy;
//	double   SATz;
//	double   ANTx;
//	double   ANTy;
//	double   ANTz;
//	double   VELx;
//	double   VELy;
//	double   VELz;
//	double   Ax;
//	double   Ay;
//	double   Az;
//	double   Sz;
//	//double   Vz;
//	double   GHAA;
//	
//	double   DS;
//	double   DF;
//	
//	/* keplerians */
//	
//	char     SAT[20];
//	long     SATNO;
//	double   YE;
//	double   TE;
//	double   IN;
//	double   RA;
//	double   EC;
//	double   WP;
//	double   MA;
//	double   MM;
//	double   M2;
//	long     RV;
//	double   ALON;
//	double   ALAT;
//	double   rxOut;
//	double   txOut;
//	
//	/* location */
//	char     LOC[20];
//	double   LA;
//	double   LO;
//	double   HT;
//	
//	double      HR;                        /* Hours */
//	double      DN;
	

	
	
	
	private:
	void	foo();
};


