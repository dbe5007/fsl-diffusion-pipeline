#!/bin/sh

####Notes & Comments####
help() {
echo ""
echo "Create PBS Scripts for BedpostX in FSL"
echo "Daniel Elbich"
echo "Cogntive, Aging, and Neurogimaging Lab"
echo "Created: 3/12/19"
echo ""
echo ""
echo " Creates subject specific PBS job files to submit to ACI batch preprocessing. Includes"
echo " optional flag to run job after creation."
echo ""
echo ""
echo "Usage:"
echo "sh createPBSBedpostX.sh --subjList <text or text file> --proj <text> --folderList <text or text file> --run"
echo ""
echo " Required arguments:"
echo ""
echo "      --subjList      Text file containing list of subjects to run (include path in filename)"
echo "      --proj          Project ID"
echo "      --folderList    Text file containing list of data directories (include path in filename)"
echo ""
echo " Optional arguments (You may optionally specify one or more of): "
echo ""
echo "      --run   	    Submit PBS job to qsub"
echo ""
echo ""
exit 1
}
[ "$1" = "--help" ] && help


#Arguement check
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
--subjList) subjList="$2"
shift # past argument
shift # past value
;;
--proj) proj="$2"
shift # past argument
shift # past value
;;
--folderList) folderList="$2"
shift # past argument
shift # past value
;;
--run) run=1
shift # past argument
shift # past value
;;
*)    # unknown option
POSITIONAL+=("$1") # save it in an array for later
shift # past argument
;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#####OTHER PBS FLAGS#####
#Delayed qsub submission line - military time
#PBS -a 2200

###Read Subject IDs###
if [[ -f $subjList ]]; then
	i=0
	while read -r LINE || [[ -n $LINE ]]; do
		subs[i]=$LINE
		let "i++"
	done < $subjList
else
	subs=$subjList
fi

###Read Folders###
if [[ -f $folderList ]]; then
	i=0
	while read -r LINE || [[ -n $LINE ]]; do
		folders[i]=$LINE
		let "i++"
	done < $folderList
else
	folders=$folderList
fi

for (( i=0;i<${#subs[@]};i++ )); do

sub=${subs[i]}

##Set project specific paths##
case "$proj" in 

PROJECT1) 	FILE='/PATH/TO/SAVED/FILE/PBS_bedpost_probtrackx_'$sub'.txt'
	ALLOCATION=open
	NODES=2
	PPN=4
	MEM=16gb
    OUTPUT='/PATH/TO/FOLDER/FOR/output'
    ERROR='/PATH/TO/FOLDER/FOR/error'
	JOBNAME='probBedx_'$sub #MAX 15 CHARACTERS!!!
	DATATYPE=dcm;;

PROJECT2) 	FILE='/PATH/TO/SAVED/FILE/PBS_bedpost_probtrackx_'$sub'.txt'
	ALLOCATION=ALLOCATION_NAME
	NODES=1
	PPN=3
	MEM=16gb
    OUTPUT='/PATH/TO/FOLDER/FOR/output'
    ERROR='/PATH/TO/FOLDER/FOR/error'
	JOBNAME='probBedx_'$sub #MAX 15 CHARACTERS!!!
	DATATYPE=nii;;
esac

/bin/cat <<EOM >$FILE
#PBS -A $ALLOCATION
#PBS -l nodes=$NODES:ppn=$PPN
#PBS -l walltime=36:00:00
#PBS -l pmem=$MEM
#PBS -o $OUTPUT
#PBS -e $ERROR
#PBS -N $JOBNAME
#PBS -mae
#PBS -M EMAIL@psu.edu

module load fsl

sh /PATH/TO/fsl-diffusion-pipeline/preprocessBedpostData.sh --subj $sub --folderDir ${folders[i]} --proj $proj --format $DATATYPE

EOM

##Optional flag will automatically submit job##
if [ -z "$run" ]
then
	echo "PBS job file created. Saving to: "$FILE
else
	echo "PBS job file created. Saving to: "$FILE
	echo "Submitting job..."
	qsub $FILE
fi
done
