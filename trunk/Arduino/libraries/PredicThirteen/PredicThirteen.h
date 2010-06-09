/*
 *  PredicThirteen.h
 *  
 *
 *  Created by Andrew Edmunds on 10-05-26.
 *  Copyright 2010 Andrew Edmunds. All rights reserved.
 *  
 *
 */
//#include <stdint.h>
//#include <math.h>
//#include <stdio.h>
//#include <sys/time.h>
#include "WProgram.h"
#include "DateTime.h"

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




class PredicThirteen {
	public:
	
	typedef struct {
		int epoch_year;//ye, then time
                float epoch_day,
		xndt2o,//ndot/2 drag parameter
		xndd6o,//n float dot/6 Drag Parameter
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
        PredicThirteen::tle_t co57; 
        
        /* Geodetic position structure used by SGP4/SDP4 code. */
	
	typedef struct	{
		float lat, lon, alt, theta;
	}  geodetic_t;
	typedef struct {
		char line1[70];
		char line2[70];
		char name[25];
		long catnum;
		long setnum;
		char designator[10];
		int year;
		float refepoch;
		float incl;
		float raan;
		float eccn;
		float argper;
		float meanan;
		float meanmo;
		float drag;
		float nddot6;
		float bstar;
		long orbitnum;
	}sat;
	/* General three-dimensional vector structure used by SGP4/SDP4 code. */
	
	typedef struct	{
		float x, y, z, w;
	}  vector_t;
	
	
	PredicThirteen::tle_t elements;
	
	void setElements(PredicThirteen::tle_t);
	int isFlagClear(int flag);
	void SetFlag(int flag);
	void ClearFlag(int flag);
	float FMod2p(float x);
	//void SGP4(float tsince, PredicThirteen::tle_t * tle, PredicThirteen::vector_t * pos, PredicThirteen::vector_t * vel);
        void setTime(long sec);
        void calc(PredicThirteen::tle_t);


};



