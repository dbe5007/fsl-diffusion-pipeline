#!/bin/bash

####Notes & Comments####
help() {
echo ""
echo "Register Diffusion Data to MNI Space"
echo "Daniel Elbich"
echo "Cogntive, Aging, and Neurogimaging Lab"
echo "Created: 1/22/19"
echo ""
echo ""
echo " Fits diffusion data to standard (MNI) space for purposes of obtaining MNI"
echo " transformation matrix. Requires data to have been formatted for bedpost"
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
echo "sh mniTransform.sh --subj <subject_ID> --proj <project>"
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

PROJECT1) 	mnitransform=/SAVEPATH/TO/TRANSFORMATION/FILE/NAMED/$subj"_MNI_Transform"
	datapath=/PATH/TO/DATA/FOLDER;;

PROJECT2) 	mnitransform=/SAVEPATH/TO/TRANSFORMATION/FILE/NAMED/$subj"_MNI_Transform"
	datapath=/PATH/TO/DATA/FOLDER;;
esac

#Check for previously run
if [ -f "$subj"_MNI.nii.gz"" ] && [ -f "$subj"_MNI.mat"" ] && [ -f "$subj"_MNI_to_Native.mat"" ]
then
	echo "Fitting to MNI already completed..."
else

	mkdir -p $mnitransform

	#Transforms diffusion data to MNI space - only needed to get transformation matrix
	echo "Fitting diffusion data to MNI space..."
	flirt -in $datapath/data.nii.gz -ref /PATH/TO/MNI152_T1_2mm_brain -out $mnitransform/$subj"_MNI.nii.gz" -omat $mnitransform/$subj"_MNI.mat" -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12  -interp trilinear

	#Invert transformation matrix to go from MNI to Native space
	echo "Inverting Transformation Matrix..."
	convert_xfm -omat $mnitransform/$subj"_MNI_to_Native.mat" -inverse $mnitransform/$subj"_MNI.mat"
fi

