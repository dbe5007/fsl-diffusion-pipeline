#!/bin/bash

####Notes & Comments####
help() {
echo ""
echo "Register regions in MNI to diffusion space"
echo "Daniel Elbich"
echo "Cogntive, Aging, and Neurogimaging Lab"
echo "Created: 1/22/19"
echo ""
echo ""
echo " Registers masks in standard (MNI) space to subject specific diffusion"
echo " space. Also creates waypoint files and masks for tract avoidance to be"
echo " used with Probtrackx. Requires MNI to subject transformation matrix. Enter"
echo " single subject ID followed by the project name."
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
echo "sh transformSeedsWaypointsTargets.sh --subj <subject_ID> --proj <project>"
echo ""
echo " Required arguments:"
echo ""
echo "	    --subj          Subject ID (no spaces)"
echo "	    --proj          Project name (no spaces)"
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

#Set project specific paths
case "$proj" in 

PROJECT1) 	mnitransform=/PATH/TO/$subj"_MNI_Transform"
	datapath=/PATH/TO/DIFFUSION/DATA/FOLDER
	standardrois=/PATH/TO/TEMPLATE/MASK/REGIONS
	maskspath=/PATH/TO/OUTPUT/masks;;

PROJECT2) 	mnitransform=/PATH/TO/$subj"_MNI_Transform"
    datapath=/PATH/TO/DIFFUSION/DATA/FOLDER
    standardrois=/PATH/TO/TEMPLATE/MASK/REGIONS
    maskspath=/PATH/TO/OUTPUT/masks;;
esac


#Check for previously run
if [ -f "$maskspath/"*waypoints.txt"" ]; then
	echo "Seed & waypoints already complete. Skipping to Probtrackx..."
else

	#Create Tract Specific Folders
	mkdir -p $maskspath/common
	mkdir -p $maskspath/tract1
	mkdir -p $maskspath/tract2

	#List waypoint & seed masks
	common="commonRegion1.nii.gz commonRegion2.nii.gz commonRegion3.nii.gz"
	tract1="RH_region1.nii LH_Region2.nii"
	waypoints="waypoint1.nii.gz waypoint2.nii.gz"

	#Transform Common Masks
	for mask in ${common[@]}; do
		echo "Transforming "$mask"..."
	
		flirt -in $standardrois/common/$mask -ref $datapath/data.nii.gz -out $maskspath/common/$subj"_"$mask -applyxfm -init $mnitransform/$subj"_MNI_to_Native.mat"

		fslmaths $maskspath/common/$subj"_"$mask -bin $maskspath/common/$subj"_"$mask
	
	done

	#Transform tract1 Tracking Masks
	for mask in ${tract1[@]}; do
		echo "Transforming "$mask"..."
	
		flirt -in $standardrois/tract1/$mask -ref $datapath/data.nii.gz -out $maskspath/tract1/$subj"_"$mask -applyxfm -init $mnitransform/$subj"_MNI_to_Native.mat"

		fslmaths $maskspath/tract1/$subj"_"$mask -bin $maskspath/tract1/$subj"_"$mask
	
	done

    #Transform tract2 Tracking Masks
    for mask in ${waypoints[@]}; do
        echo "Transforming "$mask"..."

        flirt -in $standardrois/waypoints/$mask -ref $datapath/data.nii.gz -out $maskspath/waypoints/$subj"_"$mask -applyxfm -init $mnitransform/$subj"_MNI_to_Native.mat"

        fslmaths $maskspath/waypoints/$subj"_"$mask -bin $maskspath/waypoints/$subj"_"$mask

    done

fi

	####Create Avoid Regions####
	fslmaths $maskspath/common/$subj"_commonRegion1.nii.gz" -add $maskspath/common/$subj"_commonRegion2.nii.gz" $maskspath/tract1/$subj"_Avoid1.nii.gz"

	####Create waypoint list for probtrackx####
	echo "Creating waypoint files..."
	> $maskspath/tract1/$subj"_RH_waypoint1.txt"
	echo $maskspath/common/$subj"_commonRegion3.nii.gz" >> $maskspath/tract1/$subj"_RH_waypoint1.txt"
	echo $maskspath/waypoints/$subj"_waypoint1.nii.gz" >> $maskspath/tract1/$subj"_RH_waypoint1.txt"
	
done

