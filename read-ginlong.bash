#!/bin/bash

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
#  Linux bash script to read data sent from a single Ginlong/Solis 2G inverter equipped with a 
#  Wi-Fi 'stick'.
#
#  Requires setting up the inverter stick to send data to the computer running the read-ginlong
#  script. Settings located in the advanced settings, then remote server. Add a new 'remote
#  server' with the ip address of your computer and port 9999. The inverter will send data every
#  five minutes.
#
#  change the file locations to suit your system.
#
#  read-ginlong requires the following dependencies:-
#	nc		netcat reads incoming stream
#	od		octal dump to create hex output
#	grep	compares strings etc
#	date	displays system date/time
#	bc		command line calculator
#	sed		stream edit
#  Most of these will already be installed, if not grab them from your repository.
#
#  Output of log file, format (space separated) new lines appended:-
#	Date  Time   Watts_now   Day_kWh   Total_kWh 
#
#  Output of webserver file, format (space separated) file overwritten each update:-
#	Date Time Watts_now Day_kWh Total_kWh DC_volts_1 DC_amps_1 DC_volts_2 DC_amps_2 AC_volts AC_amps AC_freq kwh_yesterday kwh_month kwh_last_month
#
#  The read-ginlong script is deliberately left simple without error reporting. It is intended
#  as a 'starting point' and proof of concept. It could easily be modified to provide more
#  information from the inverter. Furthermore the output log file can be further processed or
#  loaded into other software such as LibreOffice Calc.
#
###################################################################################################



set +o monitor 				# Make sure job control is disabled

# change these values to suit your requirements:-
logfile="ginlong.log"			# location of output log file
webfile="ginlong.status"		# location of web file with all values
listen_port=9999				# port server listens for inverter stream


# stream values found (so far) all big endian:-
header="685951b0866f"				# stream header
inverter_vdc1=33 					# offset 33 & 34 DC volts chain 1 (/10)
inverter_vdc2=35 					# offset 35 & 36 DC volts chain 2 (/10)
inverter_adc1=39 					# offset 39 & 40 DC amps chain 1 (/10)
inverter_adc2=41 					# offset 41 & 42 DC amps chain 2 (/10)
inverter_aac=45						# offset 45 & 46 AC output amps (/10)
inverter_vac=51 					# offset 51 & 52 AC output volts (/10)
inverter_freq=57 					# offset 57 & 58 AC frequency (/100)
inverter_now=59 					# offset 59 & 60 currant generation Watts
inverter_yes=67 					# offset 67 & 68 yesterday kwh (/100)
inverter_day=69 					# offset 69 & 70 daily kWh (/100)
inverter_tot=73 					# offset 73 & 74 total kWh (/10)
inverter_mth=87						# offset 87 & 88 total kWh for month 
inverter_lmth=91					# offset 91 & 92 total kWh for last month 


for (( ;; ))										# loop forever
	do
		inverter_output=`nc -l $listen_port | od -w500 -An -t x1`		# read incoming stream and convert to hex

		inverter_output=$(echo $inverter_output | sed 's/ //g')			# remove spaces from between hex values

		find_header=`echo $inverter_output | grep "^$header"`			# look for header at start of stream

		if [ "$find_header" != "" ]; then					# check header string is there

														# extract main values and convert to decimal
			watts_now=${inverter_output:$inverter_now*2:4}		# read values for watts now
			watts_now=$(echo $((16#$watts_now)))				# convert to integer

			kwh_day=${inverter_output:$inverter_day*2:4}		# read values for kWh day
			kwh_day=$(echo $((16#$kwh_day)))					# convert to integer
			kwh_day=$(echo "scale=1; $kwh_day/100" | bc)		# apply factor /100
			kwh_day=$(echo $kwh_day | sed 's/^\./0./')	 		# add leading zero

			kwh_tot=${inverter_output:$inverter_tot*2:4}		# read values for kWh day
			kwh_tot=$(echo $((16#$kwh_tot)))				 	# convert to integer				
			kwh_tot=$(echo "$kwh_tot/10" | bc)					# apply factor /10

															# extract dc input values and convert to decimal
			dc_volts1=${inverter_output:$inverter_vdc1*2:4}		# read values for DC volts 1 from chain 1
			dc_volts1=$(echo $((16#$dc_volts1)))			 	# convert to integer				
			dc_volts1=$(echo "scale=1; $dc_volts1/10" | bc)		# apply factor /10

			dc_volts2=${inverter_output:$inverter_vdc2*2:4}		# read values for DC volts 2 from chain 2
			dc_volts2=$(echo $((16#$dc_volts2)))			 	# convert to integer				
			dc_volts2=$(echo "scale=1; $dc_volts2/10" | bc)		# apply factor /10

			dc_amps1=${inverter_output:$inverter_adc1*2:4}		# read values for DC amps 1 from chain 1
			dc_amps1=$(echo $((16#$dc_amps1)))			 		# convert to integer				
			dc_amps1=$(echo "scale=1; $dc_amps1/10" | bc )		# apply factor /10
			dc_amps1=$(echo $dc_amps1 | sed 's/^\./0./')		# add leading zero

			dc_amps2=${inverter_output:$inverter_adc2*2:4}		# read values for DC amps 2 from chain 2
			dc_amps2=$(echo $((16#$dc_amps2)))			 		# convert to integer				
			dc_amps2=$(echo "scale=1; $dc_amps2/10" | bc)		# apply factor /10
			dc_amps2=$(echo $dc_amps2 | sed 's/^\./0./')		# add leading zero

															# extract other ac values and convert to decimal
			ac_volts=${inverter_output:$inverter_vac*2:4}		# read values for AC volts output
			ac_volts=$(echo $((16#$ac_volts)))			 		# convert to integer				
			ac_volts=$(echo "scale=1; $ac_volts/10" | bc)		# apply factor /10

			ac_amps=${inverter_output:$inverter_aac*2:4}		# read values for AC amps output
			ac_amps=$(echo $((16#$ac_amps)))			 		# convert to integer				
			ac_amps=$(echo "scale=1; $ac_amps/10" | bc)			# apply factor /10
			ac_amps=$(echo $ac_amps | sed 's/^\./0./')			# add leading zero

			ac_freq=${inverter_output:$inverter_freq*2:4}		# read values for AC output frequency Hertz
			ac_freq=$(echo $((16#$ac_freq)))					# convert to integer
			ac_freq=$(echo "scale=2; $ac_freq/100" | bc)		# apply factor /100

															# extract other historical values and convert to decimal
			kwh_yesterday=${inverter_output:$inverter_yes*2:4}			# read values for kWh day
			kwh_yesterday=$(echo $((16#$kwh_yesterday)))				# convert to integer
			kwh_yesterday=$(echo "scale=1; $kwh_yesterday/100" | bc)	# apply factor /100
			kwh_yesterday=$(echo $kwh_yesterday | sed 's/^\./0./')		# add leading zero

			kwh_month=${inverter_output:$inverter_mth*2:4}		# read values total kwh for month
			kwh_month=$(echo $((16#$kwh_month)))			 	# convert to integer				

			kwh_lastmonth=${inverter_output:$inverter_lmth*2:4}		# read values total kwh for last month
			kwh_lastmonth=$(echo $((16#$kwh_lastmonth)))		 	# convert to integer			


			time_stamp=$(date +'%F %H:%M')						# get date and time

			echo "$time_stamp $watts_now $kwh_day $kwh_tot" >> $logfile	# output to log (main values only)

			echo "$time_stamp $watts_now $kwh_day $kwh_tot $dc_volts1 $dc_amps1 $dc_volts2 $dc_amps2 $ac_volts $ac_amps $ac_freq $kwh_yesterday $kwh_month $kwh_lastmonth"> $webfile	# output all values, possibly for webpage
		fi

	sleep 5s									# wait five seconds

done 										# end of loop
