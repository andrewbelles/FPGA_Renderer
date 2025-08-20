## This file is a general .xdc for the Basys3 rev B board for ENGS31/CoSc56
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project
## - these names should match the external ports (_ext_port) in the entity declaration of your shell/top level

##====================================================================
## External_Clock_Port
##====================================================================
## This is a 100 MHz external clock
set_property PACKAGE_PIN W5 [get_ports clk_ext_port]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk_ext_port]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_ext_port]

##====================================================================
## Switch_ports
##====================================================================
## SWITCH 0 (RIGHT MOST SWITCH)
#set_property PACKAGE_PIN V17 [get_ports {sw_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[0]}]
## SWITCH 1
#set_property PACKAGE_PIN V16 [get_ports {sw_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[1]}]
## SWITCH 2
#set_property PACKAGE_PIN W16 [get_ports {sw_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[2]}]
## SWITCH 3
#set_property PACKAGE_PIN W17 [get_ports {sw_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[3]}]
## SWITCH 4
#set_property PACKAGE_PIN W15 [get_ports {sw_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[4]}]
## SWITCH 5
#set_property PACKAGE_PIN V15 [get_ports {sw_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[5]}]
## SWITCH 6
#set_property PACKAGE_PIN W14 [get_ports {sw_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[6]}]
## SWITCH 7
#set_property PACKAGE_PIN W13 [get_ports {sw_ext_port[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[7]}]
## SWITCH 8
#set_property PACKAGE_PIN V2 [get_ports {sw_ext_port[8]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[8]}]
## SWITCH 9
#set_property PACKAGE_PIN T3 [get_ports {sw_ext_port[9]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[9]}]
## SWITCH 10
#set_property PACKAGE_PIN T2 [get_ports {sw_ext_port[10]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[10]}]
## SWITCH 11
#set_property PACKAGE_PIN R3 [get_ports {sw_ext_port[11]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[11]}]
## SWITCH 12
#set_property PACKAGE_PIN W2 [get_ports {sw_ext_port[12]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[12]}]
## SWITCH 13
#set_property PACKAGE_PIN U1 [get_ports {sw_ext_port[13]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[13]}]
## SWITCH 14
#set_property PACKAGE_PIN T1 [get_ports {sw_ext_port[14]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[14]}]
## SWITCH 15 (LEFT MOST SWITCH)
#set_property PACKAGE_PIN R2 [get_ports {sw_ext_port[15]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {sw_ext_port[15]}]
 
##====================================================================
## LED_ports
##====================================================================
## LED 0 (RIGHT MOST LED)
#set_property PACKAGE_PIN U16 [get_ports {LED_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[0]}]
## LED 1
#set_property PACKAGE_PIN E19 [get_ports {LED_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[1]}]
## LED 2
#set_property PACKAGE_PIN U19 [get_ports {LED_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[2]}]
## LED 3
#set_property PACKAGE_PIN V19 [get_ports {LED_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[3]}]
## LED 4
#set_property PACKAGE_PIN W18 [get_ports {LED_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[4]}]
## LED 5
#set_property PACKAGE_PIN U15 [get_ports {LED_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[5]}]
## LED 6
#set_property PACKAGE_PIN U14 [get_ports {LED_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[6]}]
## LED 7
#set_property PACKAGE_PIN V14 [get_ports {LED_ext_port[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[7]}]
## LED 8
#set_property PACKAGE_PIN V13 [get_ports {LED_ext_port[8]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[8]}]
## LED 9
#set_property PACKAGE_PIN V3 [get_ports {LED_ext_port[9]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[9]}]
## LED 10
#set_property PACKAGE_PIN W3 [get_ports {LED_ext_port[10]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[10]}]
## LED 11
#set_property PACKAGE_PIN U3 [get_ports {LED_ext_port[11]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[11]}]
## LED 12
#set_property PACKAGE_PIN P3 [get_ports {LED_ext_port[12]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[12]}]
## LED 13
#set_property PACKAGE_PIN N3 [get_ports {LED_ext_port[13]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[13]}]
## LED 14
#set_property PACKAGE_PIN P1 [get_ports {LED_ext_port[14]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[14]}]
## LED 15 (LEFT MOST LED)
#set_property PACKAGE_PIN L1 [get_ports {LED_ext_port[15]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {LED_ext_port[15]}]
	
##====================================================================	
## 7 segment display
##====================================================================
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Segments
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#set_property PACKAGE_PIN W7 [get_ports {seg_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[0]}]
#set_property PACKAGE_PIN W6 [get_ports {seg_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[1]}]
#set_property PACKAGE_PIN U8 [get_ports {seg_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[2]}]
#set_property PACKAGE_PIN V8 [get_ports {seg_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[3]}]
#set_property PACKAGE_PIN U5 [get_ports {seg_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[4]}]
#set_property PACKAGE_PIN V5 [get_ports {seg_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[5]}]
#set_property PACKAGE_PIN U7 [get_ports {seg_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[6]}]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Decimal Point
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#set_property PACKAGE_PIN V7 [get_ports dp_ext_port]							
	#set_property IOSTANDARD LVCMOS33 [get_ports dp_ext_port]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Anodes
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#set_property PACKAGE_PIN U2 [get_ports {an_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[0]}]
#set_property PACKAGE_PIN U4 [get_ports {an_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[1]}]
#set_property PACKAGE_PIN V4 [get_ports {an_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[2]}]
#set_property PACKAGE_PIN W4 [get_ports {an_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[3]}]

##====================================================================
## Buttons
##====================================================================
## CENTER BUTTON
#set_property PACKAGE_PIN U18 [get_ports btnC_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnC_ext_port]
## UP BUTTON
#set_property PACKAGE_PIN T18 [get_ports btnU_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnU_ext_port]
## LEFT BUTTON
#set_property PACKAGE_PIN W19 [get_ports btnL_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnL_ext_port]
## RIGHT BUTTON
#set_property PACKAGE_PIN T17 [get_ports btnR_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnR_ext_port]
## DOWN BUTTON
#set_property PACKAGE_PIN U17 [get_ports btnD_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnD_ext_port]
 

##====================================================================
## Pmod Header JA
##====================================================================
##Sch name = JA1
#set_property PACKAGE_PIN J1 [get_ports {JA_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[0]}]
##Sch name = JA2
#set_property PACKAGE_PIN L2 [get_ports {JA_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[1]}]
##Sch name = JA3
#set_property PACKAGE_PIN J2 [get_ports {JA_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[2]}]
##Sch name = JA4
#set_property PACKAGE_PIN G2 [get_ports {JA_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[3]}]
##Sch name = JA7
#set_property PACKAGE_PIN H1 [get_ports {JA_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[4]}]
##Sch name = JA8
#set_property PACKAGE_PIN K2 [get_ports {JA_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[5]}]
##Sch name = JA9
#set_property PACKAGE_PIN H2 [get_ports {JA_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[6]}]
##Sch name = JA10
#set_property PACKAGE_PIN G3 [get_ports {JA_ext_port[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA_ext_port[7]}]


##====================================================================
## Pmod Header JB
##====================================================================
##Sch name = JB1
#set_property PACKAGE_PIN A14 [get_ports {JB_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[0]}]
##Sch name = JB2
#set_property PACKAGE_PIN A16 [get_ports {JB_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[1]}]
##Sch name = JB3
#set_property PACKAGE_PIN B15 [get_ports {JB_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[2]}]
##Sch name = JB4
#set_property PACKAGE_PIN B16 [get_ports {JB_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[3]}]
##Sch name = JB7
#set_property PACKAGE_PIN A15 [get_ports {JB_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[4]}]
##Sch name = JB8
#set_property PACKAGE_PIN A17 [get_ports {JB_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[5]}]
##Sch name = JB9
#set_property PACKAGE_PIN C15 [get_ports {JB_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[6]}]
##Sch name = JB10 
#set_property PACKAGE_PIN C16 [get_ports {JB_ext_port[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB_ext_port[7]}]
 

##====================================================================
## Pmod Header JC
##====================================================================
##Sch name = JC1
#set_property PACKAGE_PIN K17 [get_ports {JC_ext_port[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[0]}]
##Sch name = JC2
#set_property PACKAGE_PIN M18 [get_ports {JC_ext_port[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[1]}]
##Sch name = JC3
#set_property PACKAGE_PIN N17 [get_ports {JC_ext_port[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[2]}]
##Sch name = JC4
#set_property PACKAGE_PIN P18 [get_ports {JC_ext_port[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[3]}]
##Sch name = JC7
#set_property PACKAGE_PIN L17 [get_ports {JC_ext_port[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[4]}]
##Sch name = JC8
#set_property PACKAGE_PIN M19 [get_ports {JC_ext_port[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[5]}]
##Sch name = JC9
#set_property PACKAGE_PIN P17 [get_ports {JC_ext_port[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[6]}]
##Sch name = JC10
#set_property PACKAGE_PIN R18 [get_ports {JC_ext_port[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC_ext_port[7]}]

##====================================================================
## Pmod Header JXADC
##====================================================================
#Sch name = XA1_P
#set_property PACKAGE_PIN J3 [get_ports {vauxp6_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp6_ext_port}]
#Sch name = XA2_P
#set_property PACKAGE_PIN L3 [get_ports {vauxp14_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp14_ext_port}]
#Sch name = XA3_P
#set_property PACKAGE_PIN M2 [get_ports {vauxp7_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp7_ext_port}]
#Sch name = XA4_P
#set_property PACKAGE_PIN N2 [get_ports {vauxp15_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxp15_ext_port}]
#Sch name = XA1_N
#set_property PACKAGE_PIN K3 [get_ports {vauxn6_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn6_ext_port}]
#Sch name = XA2_N
#set_property PACKAGE_PIN M3 [get_ports {vauxn14_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn14_ext_port}]
#Sch name = XA3_N
#set_property PACKAGE_PIN M1 [get_ports {vauxn7_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn7_ext_port}]
#Sch name = XA4_N
#set_property PACKAGE_PIN N1 [get_ports {vauxn15_ext_port}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vauxn15_ext_port}]


##====================================================================
## VGA Connector
##====================================================================
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## RED
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set_property PACKAGE_PIN G19 [get_ports {red[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red[0]}]
set_property PACKAGE_PIN H19 [get_ports {red[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red[1]}]
set_property PACKAGE_PIN J19 [get_ports {red[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red[2]}]
set_property PACKAGE_PIN N19 [get_ports {red[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {red[3]}]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## BLUE
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set_property PACKAGE_PIN N18 [get_ports {blue[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue[0]}]
set_property PACKAGE_PIN L18 [get_ports {blue[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue[1]}]
set_property PACKAGE_PIN K18 [get_ports {blue[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue[2]}]
set_property PACKAGE_PIN J18 [get_ports {blue[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {blue[3]}]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## GREEN
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set_property PACKAGE_PIN J17 [get_ports {green[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green[0]}]
set_property PACKAGE_PIN H17 [get_ports {green[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green[1]}]
set_property PACKAGE_PIN G17 [get_ports {green[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green[2]}]
set_property PACKAGE_PIN D17 [get_ports {green[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {green[3]}]
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Timing
##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
set_property PACKAGE_PIN P19 [get_ports HS]						
	set_property IOSTANDARD LVCMOS33 [get_ports HS]
set_property PACKAGE_PIN R19 [get_ports VS]						
	set_property IOSTANDARD LVCMOS33 [get_ports VS]

##====================================================================
## USB-RS232 Interface
##====================================================================
#set_property PACKAGE_PIN B18 [get_ports RsRx_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx_ext_port]
#set_property PACKAGE_PIN A18 [get_ports RsTx_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsTx_ext_port]

##====================================================================
## USB HID (PS/2)
##====================================================================
#set_property PACKAGE_PIN C17 [get_ports PS2Clk_ext_port]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk_ext_port]
	#set_property PULLUP true [get_ports PS2Clk_ext_port]
#set_property PACKAGE_PIN B17 [get_ports PS2Data_ext_port]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data_ext_port]	
	#set_property PULLUP true [get_ports PS2Data_ext_port]

##====================================================================
## Quad SPI Flash
##====================================================================
##Note that CCLK_0 cannot be placed in 7 series devices. You can access it using the
##STARTUPE2 primitive.
#set_property PACKAGE_PIN D18 [get_ports {QspiDB_ext_port[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB_ext_port[0]}]
#set_property PACKAGE_PIN D19 [get_ports {QspiDB_ext_port[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB_ext_port[1]}]
#set_property PACKAGE_PIN G18 [get_ports {QspiDB_ext_port[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB_ext_port[2]}]
#set_property PACKAGE_PIN F18 [get_ports {QspiDB_ext_port[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB_ext_port[3]}]
#set_property PACKAGE_PIN K19 [get_ports QspiCSn_ext_port]					
	#set_property IOSTANDARD LVCMOS33 [get_ports QspiCSn_ext_port]

##====================================================================
## Implementation Assist
##====================================================================	
## These additional constraints are recommended by Digilent, DO NOT REMOVE!
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]