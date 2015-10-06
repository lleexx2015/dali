PROGRAM_NAME='sample_code'
(***********************************************************)
(*  FILE CREATED ON: 30/03/2013			           *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 9/04/2013		           *)
(***********************************************************)
(*  															                         *)
(***********************************************************)
(*!!FILE REVISION:  2                                      *)
(*  REVISION DATE:  09/04/2013	                           *)
(*                                                         *)
DEFINE_DEVICE

dvRS232_N6		= 0:14:0 	// dali 19200  8 1 none
vdvHelvar		= 33013:1:0	// Helvar DALI gate


DEFINE_CONSTANT
//define constant for DALI lighting
INTEGER	Light_On 	= 1
INTEGER Light_Off 	= 0

INTEGER light100 = 255;
INTEGER light90 = 230;
INTEGER light80 = 205;
INTEGER light70 = 180;
INTEGER light60 = 155;
INTEGER light50 = 130;
INTEGER light40 = 105;
INTEGER light30 = 80;
INTEGER light20 = 55;
INTEGER light10 = 30;
INTEGER light0 = 0;          


// simple button on control panel naming
INTEGER light_adr1=217;
INTEGER light_adr2=218;
INTEGER light_adr3=219;
INTEGER light_adr4=220;
INTEGER light_adr5=221;
INTEGER light_adr6=222;
INTEGER light_adr7=223;
INTEGER light_adr8=224;
INTEGER light_adr9=225;
INTEGER light_adr10=226;
INTEGER light_adr11=227;
INTEGER light_adr12=228;

DEFINE_VARIABLE

// state light group
PERSISTENT INTEGER light1_state;
PERSISTENT INTEGER light2_state;
PERSISTENT INTEGER light3_state;
PERSISTENT INTEGER light4_state;
PERSISTENT INTEGER light5_state;
PERSISTENT INTEGER light6_state;
PERSISTENT INTEGER light7_state;
PERSISTENT INTEGER light8_state;
PERSISTENT INTEGER light9_state;
PERSISTENT INTEGER light10_state;
PERSISTENT INTEGER light11_state;
PERSISTENT INTEGER light12_state;

PERSISTENT INTEGER light1_vol;
PERSISTENT INTEGER light2_vol;
PERSISTENT INTEGER light3_vol;
PERSISTENT INTEGER light4_vol;
PERSISTENT INTEGER light5_vol;
PERSISTENT INTEGER light6_vol;
PERSISTENT INTEGER light7_vol;
PERSISTENT INTEGER light8_vol;
PERSISTENT INTEGER light9_vol;
PERSISTENT INTEGER light10_vol;
PERSISTENT INTEGER light11_vol;
PERSISTENT INTEGER light12_vol;


INTEGER  light_level;
CHAR   light_level_char[30];
CHAR   light_level_ch[30];


/ **
    Processing of the data from the virtual port Helvar
    inlet: in_pszData - a pointer to the data
    at the exit : *
* /
define_function fnHelvarReceiveData (char in_pszData [])
{
    local_var char l_szValue [64];
    local_var char l_szCom [32];
    local_var char l_szParam1 [16];
    local_var char l_szParam2 [16];
    local_var integer l_iValue1;
    local_var integer l_iValue2;
    
    // Endless cycle
    while (1)
    {
send_command 0, in_pszData
// Get and check that the command
l_szValue = remove_string (in_pszData, ';', 1);
if (length_string (l_szValue)! = 0)
{
// Convert to uppercase
l_szValue = upper_string (l_szValue);
l_szCom = remove_string (l_szValue, '', 1);
switch (l_szCom)
{
// Set address
case 'ADDRESS':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ',', 1);
l_szParam2 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1) && length_string (l_szParam2))
{
// Get the values
l_iValue1 = atoi (l_szParam1);
l_iValue2 = atoi (l_szParam2);
// Command accepted
send_string 0, "'address:', itoa (l_iValue1), 'value:', itoa (l_iValue2)";
switch (l_iValue1)
{
case 1: {IF (l_iValue2 = 0)
{Light1_state = 0;
OFF [ads, light_adr1]} else {light1_state = 1; ON [ads, light_adr1]; light_count = 1}}
case 6: {IF (l_iValue2 = 0) {light2_state = 0; OFF [ads, light_adr2]} else {light2_state = 1; ON [ads, light_adr2]; light_count = 1}}
case 19: {IF (l_iValue2 = 0) {light3_state = 0; OFF [ads, light_adr3]} else {light3_state = 1; ON [ads, light_adr3]; light_count = 1}}
case 12: {IF (l_iValue2 = 0) {light4_state = 0; OFF [ads, light_adr4]} else {light4_state = 1; ON [ads, light_adr4]; light_count = 1}}
case 22: {IF (l_iValue2 = 0) {light5_state = 0; OFF [ads, light_adr5]} else {light5_state = 1; ON [ads, light_adr5]; light_count = 1}}
case 14: {IF (l_iValue2 = 0) {light5_state = 0; OFF [ads, light_adr5]} else {light5_state = 1; ON [ads, light_adr5]; light_count = 1}}
case 21: {IF (l_iValue2 = 0) {light5_state = 0; OFF [ads, light_adr5]} else {light5_state = 1; ON [ads, light_adr5]; light_count = 1}}
case 3: {IF (l_iValue2 = 0) {light6_state = 0; OFF [ads, light_adr6]} else {light6_state = 1; ON [ads, light_adr6]; light_count = 1}}
case 15: {IF (l_iValue2 = 0) {light6_state = 0; OFF [ads, light_adr6]} else {light6_state = 1; ON [ads, light_adr6]; light_count = 1}}
case 17: {IF (l_iValue2 = 0) {light6_state = 0; OFF [ads, light_adr6]} else {light6_state = 1; ON [ads, light_adr6]; light_count = 1}}
case 20: {IF (l_iValue2 = 0) {light6_state = 0; OFF [ads, light_adr6]} else {light6_state = 1; ON [ads, light_adr6]; light_count = 1}}
case 26: {IF (l_iValue2 = 0) {light6_state = 0; OFF [ads, light_adr6]} else {light6_state = 1; ON [ads, light_adr6]; light_count = 1}}
case 9: {IF (l_iValue2 = 0) {light6_state = 0; OFF [ads, light_adr6]} else {light6_state = 1; ON [ads, light_adr6]; light_count = 1}}
case 5: {IF (l_iValue2 = 0) {light7_state = 0; OFF [ads, light_adr7]} else {light7_state = 1; ON [ads, light_adr7]; light_count = 1}}
case 7: {IF (l_iValue2 = 0) {light7_state = 0; OFF [ads, light_adr7]} else {light7_state = 1; ON [ads, light_adr7]; light_count = 1}}
case 11: {IF (l_iValue2 = 0) {light7_state = 0; OFF [ads, light_adr7]} else {light7_state = 1; ON [ads, light_adr7]; light_count = 1}}
case 27: {IF (l_iValue2 = 0) {light7_state = 0; OFF [ads, light_adr7]} else {light7_state = 1; ON [ads, light_adr7]; light_count = 1}}
case 28: {IF (l_iValue2 = 0) {light7_state = 0; OFF [ads, light_adr7]} else {light7_state = 1; ON [ads, light_adr7]; light_count = 1}}
case 18: {IF (l_iValue2 = 0) {light8_state = 0; OFF [ads, light_adr8]} else {light8_state = 1; ON [ads, light_adr8]; light_count = 1}}
case 8: {IF (l_iValue2 = 0) {light9_state = 0; OFF [ads, light_adr9]} else {light9_state = 1; ON [ads, light_adr9]; light_count = 1}}
case 16: {IF (l_iValue2 = 0) {light10_state = 0; OFF [ads, light_adr10]} else {light10_state = 1; ON [ads, light_adr10]; light_count = 1}}
case 13: {IF (l_iValue2 = 0) {light11_state = 0; OFF [ads, light_adr11]} else {light11_state = 1; ON [ads, light_adr11]; light_count = 1}}
case 10: {IF (l_iValue2 = 0) {light12_state = 0; OFF [ads, light_adr12]} else {light12_state = 1; ON [ads, light_adr12]; light_count = 1}}
}
}
break;
}
// Pressing
case 'PRESS':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ',', 1);
l_szParam2 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1) && length_string (l_szParam2))
{
// Get the values
l_iValue1 = atoi (l_szParam1);
l_iValue2 = atoi (l_szParam2);
// Command accepted
send_string 0, "'press:', itoa (l_iValue1), 'channel:', itoa (l_iValue2)";
}
break;
}
// Pressing
case 'RELEASE':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ',', 1);
l_szParam2 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1) && length_string (l_szParam2))
{
// Get the values
l_iValue1 = atoi (l_szParam1);
l_iValue2 = atoi (l_szParam2);
// Command accepted
send_string 0, "'release:', itoa (l_iValue1), 'channel:', itoa (l_iValue2)";
}
break;
}
}
} Else
break;
    }
}

DEFINE_START


// initial dali
send_command vdvHELVAR, "'use 1;use 3;use 5;use 6;use 7;use 8;use 9;'";
send_command vdvHELVAR, "'use 10;use 11;use 12;use 13;use 14;use 15;use 16;use 17;use 18;use 19;'";
send_command vdvHELVAR, "'use 20;use 21;use 22;use 26;use 27;use 28;'";
send_command vdvHelvar, "'ADD 1,1;'";
send_command vdvHelvar, "'ADD 6, 1;'";
send_command vdvHelvar, "'ADD 19, 1;'";
send_command vdvHelvar, "'ADD 3,2;'";
send_command vdvHelvar, "'ADD 5,2;'";
send_command vdvHelvar, "'ADD 7,2;'";
send_command vdvHelvar, "'ADD 9,2;'";
send_command vdvHelvar, "'ADD 11,2;'";
send_command vdvHelvar, "'ADD 15,2;'";
send_command vdvHelvar, "'ADD 17,2;'";
send_command vdvHelvar, "'ADD 20,2;'";
send_command vdvHelvar, "'ADD 26,2;'";
send_command vdvHelvar, "'ADD 27,2;'";
send_command vdvHelvar, "'ADD 28,2;'";
send_command vdvHelvar, "'ADD 12,3;'";
send_command vdvHelvar, "'ADD 14,3;'";
send_command vdvHelvar, "'ADD 21,3;'";
send_command vdvHelvar, "'ADD 22,3;'";
send_command vdvHelvar, "'ADD 8,4;'";
send_command vdvHelvar, "'ADD 10,4;'";
send_command vdvHelvar, "'ADD 13,4;'";
send_command vdvHelvar, "'ADD 16,4;'";
send_command vdvHelvar, "'ADD 18,4;'";


DEFINE_MODULE 'Helvar_503AV_RS232' modHelvar(vdvHelvar, dvAMX_RS232_PORT_1)

DEFINE_EVENT
BUTTON_EVENT [ads, light_adr1]
{
     PUSH:
     {
switch (light1_state)
{
// Light off
case 0:
{
// Smooth increase in light in 1 second
send_command vdvHelvar, "'FADE 1,3000,254;'";
break;
}
case 1:
{
// Smooth attenuation of light in 1 second
send_command vdvHelvar, "'FADE 1,3000,0;'";
break;
}
}
     }
}
