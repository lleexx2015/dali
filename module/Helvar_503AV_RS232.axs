/**
   Module for use with the gateway Digidim 503av
    
     Application:
     1. Connect to the project DEFINE_MODULE 'Helvar_503AV_RS232' modHelvar1 (vdvHELVAR, dvAMX_RS232_PORT_1)
        where vdvHELVAR - vitualny identiifkator port and RS232 serial port physical dvAMX_RS232_PORT_1 AMX
        controller.
     2. Make the virtual port handler in the parent program like this:
	DATA_EVENT[vdvHELVAR]
	{
	    STRING:
	    {
		fnVirtualReceiveData(data.text);
	    }
  }
The handler will receive messages:
- ADDRESS adr, value; Changing the address
adr - address of the device from 1 to 63
value - a value from 0 to 254
- PUSH adr, channel; Pressing the button member
adr - address of the push-button device
channel - the channel number on the keypad unit
- RELEASE adr, channel; Forced off button member
adr - address of the push-button device
channel - the channel number on the keypad unit
    3. Use the following commands:
- BROADCAST value; Sending values ??all channels
value - value to set from 0 to 254
- GROUP group, value; Sending values ??to all group addresses
group - a group number from 1 to 16
value - value to set from 0 to 254
- ADDRESS adr, value; Sending values ??at
adr - address from 1 to 63
value - value to set from 0 to 254
- ADD adr, group; Adding an address group
adr - address from 1 to 63
group - a group number from 1 to 16
- USE adr; Flag use the address specifies whether to get information about changing values
adr - address from 1 to 63
- DEBUG flag; Enable / disable debug information
flag - the flag off the inclusion of debug information
- FADE adr, time, value; enable a smooth level changes
adr - address from 1 to 63
time - time during which the channel takes a value from 0 to 254
value - a value to which you want to raise or lower the current level of 0 to 254
*/
MODULE_NAME='Helvar_503AV_RS232' (dev vdvVirtual, dev dvDevice)
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 11:33:16        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
     05/09/2013 - Added handling of code 61
     04/09/2013 - Added all messaging
     02/09/2013 - make the team DEBUG, USE
                - To make feedback for the parent.
     01/09/2013 - make the team BROADCAST, GROUP, ADDRESS, ADD, FADE
                - At the start of the command module is sent off to all devices
     08/30/2013 - The first prototype module
*) 
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
HELVAR_PACKET_MARKER = $ 03; // Marker Package

HELVAR_INTERFACE_SEND = $ 51; // Send command data
HELVAR_INTERFACE_QUEUE = $ 55; // Command data request

HELVAR_INTERFACE_RECEIVE_61 = $ 61; // Response code ?? (appears on the bus in the presence module 910)
HELVAR_INTERFACE_RECEIVE_SEND = $ 64; // Code to respond to commands $ 51
HELVAR_INTERFACE_RECEIVE_66 = $ 66; // Response code ?? (appears on the bus in the presence module 910)
HELVAR_INTERFACE_RECEIVE_BUTTON = $ 68; // Response code buttons or keypads

// To convert the address data
HELVAR_BROADCAST = $ 80;
HELVAR_GROUP = $ 40;

// To convert clicks
HELVAR_PRESS = $ 80;

// For oboabotki addresses in the stream
ADDRESS_STOP = 0; // Stop Mode
ADDRESS_WORK = 1; // Mode

TL_WORK_ID = 1; // Stream ID

VALUE_EXT = 100; // Expansion coefficient values

// Work queue to send data
HELVAR_QUEUE_SIZE = 64; // Maximum number of items in the queue
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
// Structure describing the address
structure address_t
{
    char m_cStatus; // Condition address
    char m_cUse; // Use flag values
    char m_cGroup; // Belonging to a group
    sinteger m_siCurrentValue; // Present value
    sinteger m_siNeedValue; // The required value
    sinteger m_siAdd; // Increment
}

(************************************************* **********)
(* VARIABLE DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_VARIABLE
volatile char m_bDebug = TRUE; // Debug flag
volatile address_t m_aItems [64]; // Address value
volatile char m_pDeviceBuffer [512]; // Buffer for data gateway
volatile long m_laWorkTime [1] = 100; // Time between ticks
volatile long m_lCurrentTime = 0; // Current time
volatile char m_aQueue [HELVAR_QUEUE_SIZE] [4]; // Array storage queue
volatile integer m_iItems = 0;
volatile integer m_iWrite = 1;
volatile integer m_iRead = 1;
volatile char m_cBusy = 0;

(************************************************* **********)
(* LATCHING DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_LATCHING

(************************************************* **********)
(* MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW *)
(************************************************* **********)
DEFINE_MUTUALLY_EXCLUSIVE

(************************************************* **********)
(* SUBROUTINE / FUNCTION DEFINITIONS GO BELOW *)
(************************************************* **********)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

/ **
    Processing line
    at the entrance : *
    at the exit : *
* /
define_function fnQueueProgress ()
{
    // Check the available space in the queue
    if (! m_cBusy && m_iItems)
    {
m_cBusy = true;
// Write command from the queue to the port device
send_string dvDevice, "m_aQueue [m_iRead]";
wait 1 'Queue'
{
m_cBusy = false;
fnQueueProgress ();
}
m_iRead ++;
m_iItems--;
// Check for going beyond the stage
if (m_iRead == HELVAR_QUEUE_SIZE)
m_iRead = 1;
    }
}

/ **
    Adding commands to a queue
    inlet: in_pszCommand - these commands
    at the exit : *
* /
define_function fnAddToQueue (char in_pszCommand [4])
{
    // Check the available space in the queue
    if (m_iItems <HELVAR_QUEUE_SIZE)
    {
// Write command to the queue
m_aQueue [m_iWrite] = in_pszCommand;
m_iWrite ++;
m_iItems ++;
// Check for going beyond the stage
if (m_iWrite == HELVAR_QUEUE_SIZE)
m_iWrite = 1;
    }
    if (m_iItems)
fnQueueProgress ();
}

/ **
    Address translation in the form
    [b] [g] [n] [n] [n] [n] [n] [n]
    inlet: in_cValue - value to convert
    Output: the converted value
* /
define_function char fnGetAddress (char in_cValue)
{
    local_var char a;
    local_var char r;
    // Get the address type
    a = TYPE_CAST (in_cValue >> 6);
    // Check the broadcast address
    if (a == 3)
    {
r = HELVAR_BROADCAST;
    // Check for multicast address
    } Else if (a == 2)
    {
r = TYPE_CAST (((in_cValue >> 1) & f $) + 1);
r = r | HELVAR_GROUP;
    // Neutral address
    } Else
    {
r = TYPE_CAST ((in_cValue >> 1) + 1);
    }
    return r;
}

/ **
    Getting the value of the keys and convert to the form
    [p] [n] [n] [n] [n] [n] [n] [n]
    inlet: in_cValue - value in presenting Helvar
    Output: The value of the internal representation
* /
define_function char fnGetButton (char in_cValue)
{
    local_var char r;
    
    r = HELVAR_PRESS;
    if (in_cValue & 8)
r = 0;
    r = r | ((in_cValue & 7) + 1);
    return r;
}

/ **
    Setting the broadcast values
    inlet: in_cValue - value
    at the exit : *
* /
define_function fnSetBroadcastValue (char in_cValue)
{
    stack_var integer i;
    for (i = 1; i <= 64; i ++)
    {
m_aItems [i] .m_cStatus = ADDRESS_STOP;
m_aItems [i] .m_siCurrentValue = in_cValue * VALUE_EXT;
m_aItems [i] .m_siNeedValue = in_cValue * VALUE_EXT;
m_aItems [i] .m_siAdd = 0;
// If the address is used to notify the top
if (m_aItems [i] .m_cUse)
send_string vdvVirtual, "'ADDRESS', itoa (i), ',', itoa (m_aItems [i] .m_siCurrentValue / VALUE_EXT), ';'"
    }
}

/ **
    Setting group values
    inlet: in_cGroup - the value of the group
in_cValue - value
    at the exit : *
* /
define_function fnSetGroupValue (char in_cGroup, char in_cValue)
{
    stack_var integer i;
    for (i = 1; i <= 64; i ++)
    {
// Check Group
if (m_aItems [i] .m_cGroup == in_cGroup)
{
m_aItems [i] .m_cStatus = ADDRESS_STOP;
m_aItems [i] .m_siCurrentValue = in_cValue * VALUE_EXT;
m_aItems [i] .m_siNeedValue = in_cValue * VALUE_EXT;
m_aItems [i] .m_siAdd = 0;
// If the address is used to notify the top
if (m_aItems [i] .m_cUse)
send_string vdvVirtual, "'ADDRESS', itoa (i), ',', itoa (m_aItems [i] .m_siCurrentValue / VALUE_EXT), ';'"
}
    }
}

/ **
    Setting group values
    inlet: in_cAddress - address value
in_cValue - value
    at the exit : *
* /
define_function fnSetAddressValue (char in_cAddress, char in_cValue)
{
    // If the channel does not work in FADE
    if (m_aItems [in_cAddress] .m_cStatus == ADDRESS_STOP)
m_aItems [in_cAddress] .m_siCurrentValue = in_cValue * VALUE_EXT;

    // If the address is used to notify the top
    if (m_aItems [in_cAddress] .m_cUse)
send_string vdvVirtual, "'ADDRESS', itoa (in_cAddress), ',', itoa (m_aItems [in_cAddress] .m_siCurrentValue / VALUE_EXT), ';'"
}

/ **
    Processing data stream
    at the entrance : *
    at the exit : *
* /
define_function fnWorkThread ()
{
    local_var char i;
    local_var char s;
    local_var char o;
    // Change the time counter
    m_lCurrentTime = m_lCurrentTime + m_laWorkTime [1];
    
    // Examination of all addresses
    for (i = 1; i <= 64; i ++)
    {
// Processing modes
if (m_aItems [i] .m_cStatus == ADDRESS_WORK)
{
if (m_aItems [i] .m_siCurrentValue! = m_aItems [i] .m_siNeedValue)
{
// Remember the old value
o = TYPE_CAST (m_aItems [i] .m_siCurrentValue / VALUE_EXT);
// Increment
m_aItems [i] .m_siCurrentValue = m_aItems [i] .m_siCurrentValue + m_aItems [i] .m_siAdd;
// Check for going beyond
if (m_aItems [i] .m_siAdd> 0)
{
// Pedigree saturation
if (m_aItems [i] .m_siCurrentValue> m_aItems [i] .m_siNeedValue)
m_aItems [i] .m_siCurrentValue = m_aItems [i] .m_siNeedValue;
} Else
{
// Downward saturation
if (m_aItems [i] .m_siCurrentValue <m_aItems [i] .m_siNeedValue)
m_aItems [i] .m_siCurrentValue = m_aItems [i] .m_siNeedValue;
}
// Calculate the new value
s = TYPE_CAST (m_aItems [i] .m_siCurrentValue / VALUE_EXT);
// Send value to a physical device in case of change
if (s! = o)
fnAddToQueue ("HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, ((i - 1) * 2), s");
// send_string dvDevice, "HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, ((i - 1) * 2), s";
} Else
m_aItems [i] .m_cStatus = ADDRESS_STOP;
}
    }
}

/ **
    Processing of the data from the physical device
    at the entrance : *
    at the exit : *
* /
define_function fnDeviceReceiveData ()
{
    local_var char l_szCom [4];
    local_var char l_cAdr, l_cButton;
    
    // Check the adequacy of the data
    while (length_string (m_pDeviceBuffer)> 3)
    {
// Extract command from the buffer
l_szCom = left_string (m_pDeviceBuffer, 4);
// Check for a marker
if (l_szCom [1] == HELVAR_PACKET_MARKER)
{
switch (l_szCom [2])
{
// Information processing about getting control commands
case HELVAR_INTERFACE_RECEIVE_SEND:
case HELVAR_INTERFACE_RECEIVE_61:
{
l_cAdr = fnGetAddress (l_szCom [3])
if (l_szCom [3] & 1)
{
if (l_cAdr & HELVAR_BROADCAST)
{
// Debugging
if (m_bDebug)
send_string 0, "'Broadcast command:', itoa (l_szCom [4])";
} Else if (l_cAdr & HELVAR_GROUP)
{
// Debugging
if (m_bDebug)
If (l_szCom [4] == 0) fnSetGroupValue (l_cAdr & $ 3f, 0)
else
If (l_szCom [4] == 5) fnSetGroupValue (l_cAdr & $ 3f, 254);
send_string 0, "'Group:', itoa (l_cAdr & $ 3f), 'command:', itoa (l_szCom [4])";
} Else
{
// Debugging
if (m_bDebug)
send_string 0, "'Address:', itoa (l_cAdr & $ 3f), 'command:', itoa (l_szCom [4])";
}
} Else
{
if (l_cAdr & HELVAR_BROADCAST)
{
// Debugging
if (m_bDebug)
send_string 0, "'Broadcast value:', itoa (l_szCom [4])";
// Set values
fnSetBroadcastValue (l_szCom [4]);
} Else if (l_cAdr & HELVAR_GROUP)
{
// Debugging
if (m_bDebug)
send_string 0, "'Group:', itoa (l_cAdr & $ 3f), 'value:', itoa (l_szCom [4])";
// Set values
fnSetGroupValue (l_cAdr & $ 3f, l_szCom [4]);
} Else
{
// Debugging
if (m_bDebug)
send_string 0, "'Address:', itoa (l_cAdr & $ 3f), 'value:', itoa (l_szCom [4])";
// Set the value obtained
fnSetAddressValue (l_cAdr & $ 3f, l_szCom [4]);
}
}
break;
}
// Processing of information on pressing
case HELVAR_INTERFACE_RECEIVE_BUTTON:
{
// Debugging
if (m_bDebug)
send_string 0, "'[', itohex (l_szCom [1]), '] [', itohex (l_szCom [2]), '] [', itohex (l_szCom [3]), '] [', itohex (l_szCom [4]), ']'"

l_cAdr = fnGetAddress (l_szCom [3]);
l_cButton = fnGetButton (l_szCom [4]);
if (l_cButton & HELVAR_PRESS)
{
// Debugging
if (m_bDebug)
send_string 0, "'Press button address:', itoa (l_cAdr), 'channel:', itoa (l_cButton & ~ HELVAR_PRESS)"
// Sending to the top
send_string vdvVirtual, "'PRESS', itoa (l_cAdr), ',', itoa (l_cButton & ~ HELVAR_PRESS), ';'"
} Else
{
// Debugging
if (m_bDebug)
send_string 0, "'Release button address:', itoa (l_cAdr), 'channel:', itoa (l_cButton & ~ HELVAR_PRESS)"
// Sending to the top
send_string vdvVirtual, "'RELEASE', itoa (l_cAdr), ',', itoa (l_cButton & ~ HELVAR_PRESS), ';'"
}
break;
}
}

// Debugging
if (m_bDebug)
send_string 0, "'[', itohex (l_szCom [1]), '] [', itohex (l_szCom [2]), '] [', itohex (l_szCom [3]), '] [', itohex (l_szCom [4]), ']'"

// Remove from the buffer obrabotnnoy team
remove_string (m_pDeviceBuffer, l_szCom, 1);
} Else
{
// Clear the buffer in case of violation of integrity protocol
clear_buffer m_pDeviceBuffer;
}
    }
}

/ **
    Processing of the data from the virtual device
    at the entrance : *
    at the exit : *
* /
define_function fnVirtualReceiveData (char in_pszData [])
{
    local_var char l_szValue [64];
    local_var char l_szCom [32];
    local_var char l_szParam1 [16];
    local_var char l_szParam2 [16];
    local_var char l_szParam3 [16];
    local_var integer l_iValue1;
    local_var integer l_iValue2;
    local_var long l_lValue1;
    local_var long l_lValue2;
    
    // Endless cycle
    while (1)
    {
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
if (l_iValue1> 0 && l_iValue1 <64)
{
// Check for saturation
if (l_iValue2> $ fe)
l_iValue2 = $ fe;
// Sending device
fnAddToQueue ("HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, (l_iValue1 - 1) * 2, l_iValue2");
// send_string dvDevice, "HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, (l_iValue1 - 1) * 2, l_iValue2";
// Command accepted
if (m_bDebug)
send_string 0, "'address:', itoa (l_iValue1), 'value:', itoa (l_iValue2)";
}
}
break;
}
// Set group
case 'GROUP':
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
if (l_iValue1> 0 && l_iValue1 <= 16)
{
// Check for saturation
if (l_iValue2> $ fe)
l_iValue2 = $ fe;
// Sending device
fnAddToQueue ("HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, $ 80 + ((l_iValue1 - 1) * 2), l_iValue2");
// send_string dvDevice, "HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, $ 80 + ((l_iValue1 - 1) * 2), l_iValue2";
// Command accepted
if (m_bDebug)
send_string 0, "'group:', itoa (l_iValue1), 'value:', itoa (l_iValue2)";
}
}
break;
}
// Set all
case 'BROADCAST':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1))
{
// Get the values
l_iValue1 = atoi (l_szParam1);
// Check for saturation
if (l_iValue1> $ fe)
l_iValue1 = $ fe;
// Sending device
fnAddToQueue ("HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, $ fe, l_iValue1");
// send_string dvDevice, "HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, $ fe, l_iValue1";
// Command accepted
if (m_bDebug)
send_string 0, "'broadcast value:', itoa (l_iValue1)";
}
break;
}
// Adding an address to a group
case 'ADD':
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
if (l_iValue1> 0 && l_iValue1 <64 && l_iValue2 <= 16)
{
// Command accepted
m_aItems [l_iValue1] .m_cGroup = TYPE_CAST (l_iValue2);
// Debugging
if (m_bDebug)
send_string 0, "'address:', itoa (l_iValue1), 'add to group:', itoa (l_iValue2)";
}
}
break;
}
// Set the flag use addresses
case 'USE':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1))
{
// Get the values
l_iValue1 = atoi (l_szParam1);
if (l_iValue1> 0 && l_iValue1 <64)
{
// Command accepted
m_aItems [l_iValue1] .m_cUse = true;
// Debugging
if (m_bDebug)
send_string 0, "'use:', itoa (l_iValue1)";
}
}
break;
}
// Enable / disable debugging
case 'DEBUG':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1))
{
// Get the values
m_bDebug = atoi (l_szParam1);
send_string 0, "'debug:', itoa (m_bDebug)";
}
break;
}
// Smooth change brightness
case 'FADE':
{
// Retrieve the value of the strings
l_szParam1 = remove_string (l_szValue, ',', 1);
l_szParam2 = remove_string (l_szValue, ',', 1);
l_szParam3 = remove_string (l_szValue, ';', 1);
// Check for options
if (length_string (l_szParam1) && length_string (l_szParam2) && length_string (l_szParam3))
{
// Get the values
l_iValue1 = atoi (l_szParam1);
l_lValue1 = atol (l_szParam2);
l_iValue2 = atoi (l_szParam3);
if (l_iValue1> 0 && l_iValue1 <64)
{
// Check for saturation
if (l_lValue1> = 100000)
l_lValue1 = 100000;
if (l_iValue2> $ fe)
l_iValue2 = $ fe;
// Filling structure
m_aItems [l_iValue1] .m_cStatus = ADDRESS_WORK;
m_aItems [l_iValue1] .m_siNeedValue = TYPE_CAST (l_iValue2) * VALUE_EXT;
// Calculate the increment
l_lValue2 = ($ fe * VALUE_EXT * m_laWorkTime [1]) / l_lValue1;
if (m_aItems [l_iValue1] .m_siNeedValue <m_aItems [l_iValue1] .m_siCurrentValue)
l_lValue2 = -l_lValue2;
m_aItems [l_iValue1] .m_siAdd = l_lValue2;
// Debugging
if (m_bDebug)
send_string 0, "'fade:', itoa (l_iValue1), 'time:', itoa (l_lValue1), 'value:', itoa (l_iValue2)";
}
}
break;
}
// Value is not found
default:
{
// Debugging
if (m_bDebug)
send_string 0, "'Command:', l_szCom";
}
}
} Else
break;

    }
}

(************************************************* **********)
(* STARTUP CODE GOES BELOW *)
(************************************************* **********)
DEFINE_START
// Binding of the input data buffer
create_buffer dvDevice, m_pDeviceBuffer;

(************************************************* **********)
(* THE EVENTS GO BELOW *)
(************************************************* **********)
DEFINE_EVENT

/ **
    Handler flow
    at the entrance : *
    at the exit : *
* /
TIMELINE_EVENT [TL_WORK_ID]
{
    if (timeline.sequence == 1)
fnWorkThread ();
}

/ **
    Handler physical port gateway Helvar
    at the entrance : *
    at the exit : *
* /
DATA_EVENT [dvDevice]
{
    // Processing of the event the primary initialization
    ONLINE:
    {
// Configure port
send_command dvDevice, "'SET BAUD 19200, N, 8,1 485 DISABLE'";
// Clear the input buffer
clear_buffer m_pDeviceBuffer;
// Create a stream
timeline_create (TL_WORK_ID, m_laWorkTime, 1, timeline_absolute, timeline_repeat)
// Initialization string
send_string dvDevice, "HELVAR_PACKET_MARKER, $ 82, $ 02, $ 00";
// Switch off all channels
send_string dvDevice, "HELVAR_PACKET_MARKER, HELVAR_INTERFACE_SEND, $ fe, 0";
    }
    // Processing of the event data acquisition
    STRING:
    {
fnDeviceReceiveData ();
    }
}

/ **
    Processor virtual port
    at the entrance : *
    at the exit : *
* /
DATA_EVENT [vdvVirtual]
{
    // Process events receive commands
    COMMAND:
    {
fnVirtualReceiveData (data.text);
    }
}

(************************************************* **********)
(* THE ACTUAL PROGRAM GOES BELOW *)
(************************************************* **********)
DEFINE_PROGRAM

(************************************************* **********)
(* END OF PROGRAM *)
(* DO NOT PUT ANY CODE BELOW THIS COMMENT *)
(************************************************* **********)
