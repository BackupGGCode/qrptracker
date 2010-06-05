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
#ifndef pred13t
#define pred13t
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
#define INTCONST 10000000 /* Multiples doubles by this to save precision */








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
	Pred13t::tle_t co57;
    
	
	void setElements(Pred13t::tle_t);
        void printVar(char *name, double var);
        
        void printDouble(double val);
        
	int isFlagClear(int flag);
	void SetFlag(int flag);
	void ClearFlag(int flag);
	double FMod2p(double x);
	void SGP4(double tsince, Pred13t::tle_t * tle, Pred13t::vector_t * pos, Pred13t::vector_t * vel);
        void setTime(double unixTimeAndMicroseconds);
        void calc(tle_t tle);
		double Degrees(double arg);
		double AcTan(double sinx, double cosx);
		double Frac(double arg);
		double Modulus(double arg1, double arg2);
		double ThetaG_JD(double jd);
		double Sqr(double arg);
		void Magnitude(vector_t *v);
		void Scale_Vector(double k, vector_t *v);
		void Convert_Sat_State(vector_t *pos, vector_t *vel);
		void printTle(tle_t *tle);
		void select_ephemeris(tle_t *tle);
		void Calculate_LatLonAlt(double time, vector_t *pos, geodetic_t *geodetic);
		void printVector(vector_t *vector);
		void printGeo(geodetic_t *geo);
		double Julian_Date_of_Year(double year);
		double Julian_Date_of_Epoch(double epoch);
		


	

};
#endif

