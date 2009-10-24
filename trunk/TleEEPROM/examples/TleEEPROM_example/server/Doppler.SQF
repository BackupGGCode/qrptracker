; For Hints look at the end of this file.
; Do not remove or modify these first
; 3 lines of the file, starting with ';'!
AO-10,145900.0,435100.0,USB,LSB,REV,0,0
AO-51,435300,145920,FM,FM,Nor,0,0,Vox
AO-51,435300,145880,FM,FM,Nor,0,0,QRP
VO-52,145900,435250.3,USB,LSB,REV,0,0
AO-07,145950,432147.5,USB,LSB,REV,0,0,B
AO-07,29450,145900,USB,USB,NOR,0,0,A
UOSAT-12,437400,0,FM,FM,NOR,0,0
SO-41,436775.0,145850.0,FM,FM,NOR,0,0
SO-50,436795,145850,FM,FM,NOR,0,0
AO-16,437051,145900,USB,FM,NOR,0,0
DO-17,145825,0,FM,FM,NOR,0,0
WO-18,437075,0,USB,FM,NOR,0,0
WO-18,437102,0,USB,FM,NOR,0,0
LO-19,437125,145840,USB,FM,NOR,0,0
ISS,145800,145990,FM,FM,NOR,0,0,Packet
FO-20,435848.75,145948.55,USB,LSB,REV,0,0
FO-29,435850.45,145951.55,USB,LSB,REV,0,0
TIUNGSAT-1,437325,145850,FM,FM,NOR,0,0
GO-32,435225,145890,FM,FM,NOR,0,0
GO-32,435225,145850,FM,FM,NOR,0,0
GO-32,435225,145930,FM,FM,NOR,0,0
UO-22,435120,145900,FM,FM,NOR,0,0
UO-22,435120,145975,FM,FM,NOR,0,0
UO-22,435120,145900,PKT,PKT,NOR,0,0
UO-22,435120,145975,PKT,PKT,NOR,0,0
KO-23,435175,145900,FM,FM,NOR,0,0
KO-23,435175,145850,FM,FM,NOR,0,0
KO-25,436503,145980,FM,FM,NOR,0,0
KO-25,436503,145870,FM,FM,NOR,0,0
IO-26,435822,145875,FM,FM,NOR,0,0
IO-26,435822,145900,FM,FM,NOR,0,0
IO-26,435822,145925,FM,FM,NOR,0,0
IO-26,435822,145950,USB,FM,NOR,0,0
AO-27,436795,145850,FM,FM,NOR,0,0
UARS,438375,430775,FM,FM,NOR,0,0
TO-31,436925,145925,FM,FM,NOR,0,0
CO-57,436847.5,0,CW,CW,NOR,0,0
CO-56,437385,0,CW,CW,NOR,0,0
CO-58,437465,0,CW,CW,NOR,0,0
CO-66,437485,0,CW,CW,NOR,0,0
SUMB,435350,145880,FM,FM,NOR,0,0
CO-65,437257,0,CW,CW,NOR,0,0
ITU,437325,0,CW,CW,NOR,0,0
; Hints
; This file contains all data required for the CAT tuning to operate. CAT tuning 
; only works for satellites whose frequencies are contained in the file. 
; To use the program's tuning functions during Vfo operation, these data are also 
; needed.
; It is essential not to modify the file format, when you edit the file.
; Be careful not to add blanks or blank lines. For decimal markers, the point 
; has to be used.
; To add another satellite, copy one of the lines, insert the copy into the 
; data section, then modify it for the new satellite.
;
; Each line has to contain the following parameters:
; The name of the satellite, the spelling has to be the same as in the Keplerian
; source file.
; the receive- and transmit frequencies in kHz,
; the Up- and Downlink modes, possible entries: FM,FMN,CW,CWN,USB,LSB,
; the frequency trend of the satellite (normal or reverse), possible entries: NOR, REV
; the converter and transverer offset frequencies in kHz
;
; As a general rule, all 7 parameters have to be present, even if some of them 
; are irrelevant for a particular satellite. In that case the unused data may 
; have any value.
; 
; Each line may contain a short comment at it's end, see the examples in  
; the data lines for AO-51. The comment must be separated by a comma from
; the last parameter entry.
; 
; If the receiving frequency is the only one needed (UO-11), the transmitting 
; frequency has to be set to 0.
; Converter and transverter offsets also have to be 0, if no converter or 
; transverter is needed for the satellite concerned.
; For satellites using multiple frequencies or frequency pairs, the name has to 
; be repeated each time. At program start, the first file encountered for a specific
; satellite will be used. By editing the file, you should therefore pay attention 
; to put the most used frequency as a first entry in the list.
; 
; For more detailed informations read the manual, section 'Auxiliary files',
; 'Doppler.SQF'. For more detailed informations about converter/transverter
; operation read the FAQ.htm, section 'Converter/Transverter Operation'.
