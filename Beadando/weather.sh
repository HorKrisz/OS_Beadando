#!/bin/bash

if [ "$#" -le 0 ]
then
	echo ""
	echo "Parameterek: -l (location)"
	echo "	     -d (date)"
	echo "--------------------------"
	echo "$0 -l varosnev -d YYYY-MM-DD"
	exit
fi

if [ "$#" -gt 6 ]
then
	echo ""
	echo "Túl sok parameter"
	exit
fi

trap exit_handler EXIT

function exit_handler() {
	if [ -f result.txt ]
	then
		rm result.txt
		rm result2.txt
		rm result3.txt
	fi
}


while getopts 'l:d:' option
do
	case "$option" in
		l) l=${OPTARG}
		   LOCATION="$(echo "$l" | sed 's/_/+/g')";;
		d) if [ "$LOCATION" = "" ]
		   then
			echo "A datum csak akkor adhato meg, ha van megadva varos"
			exit
		   fi
		   d=${OPTARG}
		   DATE="$d"
	esac
done

if [ "$LOCATION" = "" ]
then
	exit
fi

function Kiir() {
	row="$1"
	echo "-----------------------------------------"
	echo -n "Datum: "
	echo "$row " | cut -d , -f 6 | cut -d : -f 2 | sed 's/\"//g'
	echo -n "Ido: "
	echo "$row " | cut -d , -f 2 | cut -d : -f 2 | sed 's/\"//g'
	echo -n "Minimum homerseklet: "
	echo "$row " | cut -d , -f 7 | cut -d : -f 2 | sed 's/\"//g'
	echo -n "Maximum homerseklet: "
	echo "$row " | cut -d , -f 8 | cut -d : -f 2 | sed 's/\"//g'
	echo -n "Homerseklet: "
	echo "$row " | cut -d , -f 9 | cut -d : -f 2 | sed 's/\"//g'
	echo "-----------------------------------------"
	echo ""
}

curl -s https://www.metaweather.com/api/location/search/?query="$LOCATION" > result.txt

cat result.txt | cut -d , -f 3 > result2.txt

WOEID=`cat result2.txt | cut -d : -f 2`

curl -s https://www.metaweather.com/api/location/"$WOEID"/ > result2.txt

cat result2.txt | sed 's/},/|/g' > result3.txt

IFS='|' read -ra ROWS < result3.txt
LENGTH=`expr ${#ROWS[*]} - 7`
echo "$LOCATION" | sed 's/+/ /g'
TRIES=0
for (( i = 0; i <= $LENGTH; i++ ));
do
	if [ "$DATE" != "" ]
	then
		while [ "$(echo "${ROWS[i]}" | cut -d , -f 6 | cut -d : -f 2 | sed 's/\"//g')" != "$DATE" ]
		do
			i=$((i+1))
			TRIES=$((TRIES+1))
			if [ "$TRIES" = "$LENGTH" ]
			then
				echo "A datum nem elerheto"
				exit
			fi
		done
		Kiir "${ROWS[i]}"
		exit
	fi
	Kiir "${ROWS[i]}"
done
