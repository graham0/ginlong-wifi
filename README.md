# ginlong-wifi
Collect data from a second generation Ginlong/Solis inverter equipped with a WIFI stick. 

#Introduction
A Ginlong/Solis second generation inverter equipped with a WIFI 'stick' sends it's data to the Ginlong
Monitoring website (http://www.ginlongmonitoring.com/) once every five minutes, when the inverter is 
live. It is also possible to log onto the WIFI 'stick' locally with a browser to configure the inverter
and read the five minute updated generation stats. 

Assuming you have already set up your system to do this. If not back-pedal a bit and get that working
first. Refer to the instructions provided.

Once you have set up your account on the Ginlong website you can view graphs and statistics compiled
from the automatically uploaded data from your inverter. You can also make this information public so
that other people also view it.

But what if you want to compile your own statistics, or automate energy usage depending on available
power yourself? The local web page relies very heavily on Java script making it difficult to automate
reading the inverter's stats. Another option is to get the inverter to send the data it sends to 
Ginlong monitoring to a local computer on your own network.

#Configuring the inverter
Log onto your inverter and click on 'Advanced'
Now click 'Remote server'
Enter a new ip address for 'Server B' (your computer) enter a port number (default 9999) select 'TCP' 
Click the 'Test' button and a tick should appear.
Click 'Save' and and when prompted 'Restart'

#Using the script(s)
There are two scripts here, 'read-ginlong.bash' and 'read-ginlong.py' the bash script uses bash
commands and needs to be ran on a Linux machine. The other is written in Python and should run on
any Python enabled system, although this one is also for Linux based systems. You only need one of 
them, they both do the same thing.

Open the one you wish to use with a text editor and set the file locations for the log file and the 
webfile to suit your system. The defaults should work for a standard Linux installation.

The files have plenty of comments and help inside them so I won't repeat it here. Both versions are
deliberately left simple without error reporting. All the variables have readable names to make them
easy to follow/modify. 

Once you have modified the file locations inside the file set it running. Wait for a few minutes and 
the first entry should appear when the inverter sends it's data. You may have to disable/modify any
running firewall on your system.

#The output files
Both programs produce the same output.

The 'logfile' contains 5 values separated by spaces, as follows:-

	Date  Time   Watts_now   Day_kWh   Total_kWh 

Each new entry occupies it's own line, new entries are appended to the end of the file as they arrive.

The 'webfile' contains 15 values again space delimited:-

	Date Time Watts_now Day_kWh Total_kWh DC_volts_1 DC_amps_1 DC_volts_2 DC_amps_2 AC_volts
	AC_amps AC_freq kwh_yesterday kwh_month kwh_last_month

Each new entry overwrites the existing one. The intention is to use this file to display currant 
information on a webpage.

#Disclaimer
This works fine on my Solis 3.6 2G inverter equipped with a WIFI 'stick'. According to Ginlong, the 
WIFI stick is compatible with all it's current solar and wind generation 2G inverters. It would be
logical therefore to assume that these scripts would be compatible with all the current second
generation inverters. The simple fact is that I only have one inverter installed and these scripts
work for me! Please feel free to try them on other Ginlong inverters and let me know how you get on,
please.
