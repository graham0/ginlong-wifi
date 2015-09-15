#!/usr/bin/python

###################################################################################################
#
#  Copyright 2015 Graham Whiteside, Manchester, UK. Version 0.2 Sept 2015.
#
#  read-ginlong is free software: you can redistribute it and/or modify it under the terms of the
#  GNU General Public License as published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  read-ginlong is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
#  even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
#  General Public License for more details.
#
#  You can browse the GNU license here: <http://www.gnu.org/licenses/>.
#
###################################################################################################

###################################################################################################
#
#  Python program to read data sent from a single Ginlong/Solis 2G inverter equipped with a 
#  Wi-Fi 'stick'.
#
#  Requires setting up the inverter stick to send data to the computer running the read-ginlong
#  script. Settings located in the advanced settings, then remote server. Add a new 'remote
#  server' with the ip address of your computer and port 9999. The inverter will send data every
#  five minutes.
#
#  Output file format (space separated):-
#	Date  Time   Watts_now   Day_kWh   Total_kWh 
#
#  Output of webserver file, format (space separated) file overwritten each update:-
#	Date Time Watts_now Day_kWh Total_kWh DC_volts_1 DC_amps_1 DC_volts_2 DC_amps_2 AC_volts AC_amps AC_freq kwh_yesterday kwh_month kwh_last_month
#
#  The read-ginlong.py program is deliberately left simple without error reporting. It is intended
#  as a 'starting point' and proof of concept. It could easily be modified to provide more
#  information from the inverter. Furthermore the output log file can be further processed or
#  loaded into other software such as LibreOffice Calc.
#
###################################################################################################
 
import socket, binascii, time


# change these values to suit your requirements:- 
HOST = ''	        	 				# Hostname or ip address of interface, leave blank for all
PORT = 9999              				# listening on port 9999
logfile = 'ginlong.log'					# location of output log file
webfile = 'ginlong.status'				# location of web file
 

# inverter values found (so far) all big endian 16 bit unsigned:-
header = '685951b0866f'				# hex stream header
data_size = 206                     # hex stream size 
inverter_vdc1 = 33 					# offset 33 & 34 DC volts chain 1 (/10)
inverter_vdc2 = 35 					# offset 35 & 36 DC volts chain 2 (/10)
inverter_adc1 = 39 					# offset 39 & 40 DC amps chain 1 (/10)
inverter_adc2 = 41 					# offset 41 & 42 DC amps chain 2 (/10)
inverter_aac = 45					# offset 45 & 46 AC output amps (/10)
inverter_vac = 51 					# offset 51 & 52 AC output volts (/10)
inverter_freq = 57 					# offset 57 & 58 AC frequency (/100)
inverter_now = 59 					# offset 59 & 60 currant generation Watts
inverter_yes = 67 					# offset 67 & 68 yesterday kwh (/100)
inverter_day = 69 					# offset 69 & 70 daily kWh (/100)
inverter_tot = 73 					# offset 73 & 74 total kWh (/10)
inverter_mth = 87					# offset 87 & 88 total kWh for month 
inverter_lmth = 91					# offset 91 & 92 total kWh for last month 


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)   # create socket on required port
sock.bind((HOST, PORT))


while True:		# loop forever
    sock.listen(1)							# listen on port
    conn, addr = sock.accept()				# wait for inverter connection
    rawdata = conn.recv(1000)				# read incoming data
    hexdata = binascii.hexlify(rawdata)		# convert data to hex

    if(hexdata[0:12] == header and len(hexdata) == data_size):		# check for valid data
           
																			# extract main values and convert to decimal
        watt_now = str(int(hexdata[inverter_now*2:inverter_now*2+4],16))    		# generating power in watts
        kwh_day = str(float(int(hexdata[inverter_day*2:inverter_day*2+4],16))/100)	# running total kwh for day
        kwh_total = str(int(hexdata[inverter_tot*2:inverter_tot*2+4],16)/10)		# running total kwh from installation

																			# extract dc input values and convert to decimal
        dc_volts1= str(float(int(hexdata[inverter_vdc1*2:inverter_vdc1*2+4],16))/10)	# input dc volts from chain 1
        dc_volts2= str(float(int(hexdata[inverter_vdc2*2:inverter_vdc2*2+4],16))/10)	# input dc volts from chain 2
        dc_amps1 = str(float(int(hexdata[inverter_adc1*2:inverter_adc1*2+4],16))/10)	# input dc amps from chain 1
        dc_amps2 = str(float(int(hexdata[inverter_adc2*2:inverter_adc2*2+4],16))/10)	# input dc amps from chain 2

																			# extract other ac values and convert to decimal
        ac_volts = str(float(int(hexdata[inverter_vac*2:inverter_vac*2+4],16))/10)		# output ac volts 
        ac_amps = str(float(int(hexdata[inverter_aac*2:inverter_aac*2+4],16))/10)		# output ac amps 
        ac_freq = str(float(int(hexdata[inverter_freq*2:inverter_freq*2+4],16))/100)	# output ac frequency hertz

																			# extract other historical values and convert to decimal
        kwh_yesterday = str(float(int(hexdata[inverter_yes*2:inverter_yes*2+4],16))/100)	# yesterday's kwh
        kwh_month = str(int(hexdata[inverter_mth*2:inverter_mth*2+4],16))					# running total kwh for month
        kwh_lastmonth = str(int(hexdata[inverter_lmth*2:inverter_lmth*2+4],16))				# running total kwh for last month


        timestamp = (time.strftime("%F %H:%M"))		# get date time
  
        log = open(logfile,'a')        # write data to logfile, main values only
        log.write(timestamp + ' ' + watt_now + ' ' + kwh_day + ' ' + kwh_total + '\n')
        log.close()

        web = open(webfile,'w')        # output all values, possibly for webpage
        web.write(timestamp + ' ' + watt_now + ' ' + kwh_day + ' ' + kwh_total + ' ' + dc_volts1 + ' ' + dc_amps1 + ' ' + dc_volts2 + ' ' + dc_amps2 + ' ' + ac_volts + ' ' + ac_amps + ' ' + ac_freq + ' ' + kwh_yesterday + ' ' + kwh_month + ' ' + kwh_lastmonth + '\n')
        web.close()

conn.close()
