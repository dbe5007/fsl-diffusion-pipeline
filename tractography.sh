#!/bin/bash

####Notes & Comments####
help() {
echo ""
echo "Probtrackx Automation"
echo "Daniel Elbich"
echo "Cogntive, Aging, and Neurogimaging Lab"
echo "Created: 1/22/19"
echo ""
echo ""
echo " Automated Probtrackx execution using seeds & masks created from"
echo " transformseeds script. Requires data to have been formatted for bedpost"
echo " processing (e.g. data.nii.gz). Enter single subject ID followed by the"
echo " project name."
echo ""
echo "Updated: 1/30/19"
echo "Added case gates to switch between project specific data paths."
echo ""
echo "Updated: 2/15/19"
echo "Revised to be single subject input rather than multi. Added flags for subject"
echo "and project information"
echo ""
echo ""
echo "Usage:"
echo "sh tractography.sh --subj <subject_ID> --proj <project>"
echo ""
echo " Required arguments:"
echo ""
echo "	    --subj        Subject ID (no spaces)"
echo "	    --proj        Project name (no spaces)"
echo ""
echo " Optional arguments:"
echo ""
echo "	    --tract       Read in list of tracts to run"
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

--subj) subj="$2"
shift # past argument
shift # past value
;;
--proj) proj="$2"
shift # past argument
shift # past value
;;
--tract) tractList="$2"
i=0
while read -r LINE || [[ -n $LINE ]]; do
	tracts[i]=$LINE
	let "i++"
	echo $tracts
done < $tractList
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


##Invoked Location##
invokeFlag=$(ps -o stat= -p $$)
if [ $invokeFlag = "S+" ]
then
	echo "Beginning "$subj"..."
fi

##Set project specific paths##
case "$proj" in 

PROJECT1) 	maskspath=/PATHS/TO/masks
	bedpostpath=/PATH/TO/$subj".bedpostX"
	analysispath=/PATH/TO/OUTPUT/FOLDER;;

PROJECT2) 	maskspath=/PATHS/TO/masks
    bedpostpath=/PATH/TO/$subj".bedpostX"
    analysispath=/PATH/TO/OUTPUT/FOLDER;;
esac

if [ -z "$tracts" ]
then
	tracts={'tract1' 'tract2'}
fi


####Probtrackx Analyses####
for tract in ${tracts[@]}; do

###Common flags###
stepnum=2000
steplength=0.5
perms=5000
fiberthres=0.01
distthresh=0.0
sampvox=0.0
waypointcond=AND
subjectdata=$bedpostpath/merged
subjectmask=$bedpostpath/nodif_brain_mask

echo "Creating output directories for "$tract"..."
mkdir -p $analysispath/$USER"_"$subj/$tract
echo "Running Probtrackx for " $tract "..."

#Code for probtrackx tracking. Easily update seeds, targets, and waypoints to add new tracts
case "$tract" in

tract1)  seedmask=$maskspath/common/$subj"_RH_region1.nii.gz"
       curve=0.50
       avoid=$maskspath/tract1/$subj"_Avoid_RH_avoid1.nii.gz"
       target=$maskspath/common/$subj"_RH_region2.nii.gz"
       waypoints=$maskspath/tract1/$subj"_RH_waypoint1.txt"
       outputdir=$analysispath/$USER"_"$subj/$tract/"output_curve_"$curve;;

tract2)  seedmask=$maskspath/common/$subj"_LH_region1.nii.gz"
       curve=0.50
       avoid=$maskspath/tract2/$subj"_Avoid_LH_avoid1.nii.gz"
       target=$maskspath/common/$subj"_LH_region2.nii.gz"
       waypoints=$maskspath/tract2/$subj"_LH_waypoint2.txt"
       outputdir=$analysispath/$USER"_"$subj/$tract/"output_curve_"$curve;;

esac

if [[ $tract == *"tract2" ]];
then
#Code for if no target mask is used
	probtrackx2 -x $seedmask -l --onewaycondition -c $curve -S $stepnum --steplength=$steplength -P $perms --fibthresh=$fiberthres --distthresh=$distthresh --sampvox=$sampvox --waycond=$waypointcond --avoid=$avoid --waypoints=$waypoints --forcedir --opd -s $subjectdata -m $subjectmask --dir=$outputdir --modeuler
else
#Code for using target mask
	probtrackx2 -x $seedmask -l --onewaycondition -c $curve -S $stepnum --steplength=$steplength -P $perms --fibthresh=$fiberthres --distthresh=$distthresh --sampvox=$sampvox --waycond=$waypointcond --avoid=$avoid --targetmasks=$target --waypoints=$waypoints --forcedir --opd -s $subjectdata -m $subjectmask --dir=$outputdir --modeuler
fi

echo "Tracking complete. Output is saved in: "$analysispath/$USER"_"$subj/$tract

done


