#!/bin/bash

#directory="`pwd`/BluetoothControl"
directory="`pwd`/Compositor"
suffix="config"

browsefolders ()
{
  for i in "$1"/*; 
  do 
    #   echo ${i#*.}
    extension=`echo "$i" | cut -d'.' -f2`
    if     [ -f "$i" ]; then        

        if [ $extension == $suffix ]; then
	    sed 's/^[ \t]+//g' < $i > temp.config
	    mv temp.config $i
	    cmake-format $i -c CMakeFormat.in > temp.config
	    mv temp.config $i
	    pareseconfig $i
            echo "$i ends with $suffix"
        fi
    elif [ -d "$i" ]; then  
    browsefolders "$i"
    fi
  done
}

writeconfig ()
{
   string=$(echo $3 |  sed -e 's/^[ \t]*//')
   index=1
   while (test "$index" -le $2)
   do
       string=$(echo "    $string")
       index=$((index + 1))
   done
   index=1
   while (test "$index" -le $1)
   do
      string=$(echo "    $string")
      index=$((index + 1))
   done
   echo "$string" >> $4
}

pareseconfig ()
{
  #While loop to read line by line
  prefix="    "
  controlstatement=0
  mapnestcount=0
  while IFS= read -r line;
  do
    readLine="$line"
    trimmedLine=$(echo $line | xargs)
    
    #If the line starts with ST then echo the line
    if [[ $trimmedLine = if* ]]; then
        controlstatement=$((controlstatement + 1))
	if [[ $mapnestcount -ge $controlstatement ]]; then
	    controlstatement=$((controlstatement - 1))
        fi
    elif [[ $trimmedLine = endif* ]]; then
	if [[ $controlstatement > 0 ]]; then
            controlstatement=$((controlstatement - 1))
        fi
    fi
    if [[ $trimmedLine = map* ]]; then
        mapnestcount=$((mapnestcount + 1))
	if [[ $mapnestcount > 1 ]]; then
		writeconfig $((mapnestcount-1)) $controlstatement "$readLine" temp.config
        else
            echo "$readLine" >> temp.config
        fi
    elif [[ $trimmedLine = end* ]]; then
	if [[ $mapnestcount > 1 ]]; then
                mapnestcount=$((mapnestcount - 1));
		writeconfig $((mapnestcount-1)) $controlstatement "$readLine" temp.config
        else
           echo "$readLine" >> temp.config
        fi
    
    elif [[ $trimmedLine = key* ]]; then
	    writeconfig $mapnestcount $controlstatement "$readLine" temp.config

    elif [[ $trimmedLine = kv* ]];  then
	    writeconfig $mapnestcount $controlstatement "$readLine" temp.config
    else
        echo "$readLine" >> temp.config
    fi
  done < "$1"
  mv temp.config $1
}
browsefolders  "$directory"
