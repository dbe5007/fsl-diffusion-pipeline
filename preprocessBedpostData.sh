#!/bin/bash

####Notes & Comments####
help() {
echo ""
echo "Clean & preprocess data using FSL"
echo "Daniel Elbich"
echo "Cogntive, Aging, and Neurogimaging Lab"
echo "Created: 1/22/19"
echo ""
echo "Updated: 1/30/19"
echo "Added case gates to switch between project specific data paths."
echo ""
echo ""
echo "Usage:"
echo "sh preprocessBedpostData.sh --subj <subject_ID> --folder <folder> --proj <project> --format <text>"
echo ""
echo ""
echo " Performs basic preprocessing of diffusion data using FSL. Script averages b0 images"
echo " (if necessary), corrects for eddy current distortions, and begins BedpostX"
echo " processing. If data is in DICOM format, files are first put through MRICron"
echo " (https://www.nitrc.org/projects/mricron) to convert to 4D-Nifti format "
echo " and obtain b-table."
echo ""
echo "Required arguments:"
echo ""
echo "	    --subj          Subject ID (no spaces)"
echo "      --folder        Directory of diffusion data"
echo "	    --proj	    Project name (no spaces)"
echo "      --format        Data format (i.e. dcm, nii)"
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
--folder) folder="$2"
shift # past argument
shift # past value
;;
--proj) proj="$2"
shift # past argument
shift # past value
;;
--format) format="$2"
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


#Change to subject directory
case "$proj" in 

#Example 1 - data is in DICOM format and requires conversion to NII
PROJECT1) 	cd /PATH/TO/DICOM/$folder
	dicompath=/PATH/TO/DICOM/$folder
	niipath=/PATH/TO/NIFTI/$folder
     	divisor=10;;

#Example 2 - data already in NII format, but in folder with multiple other nii files
PROJECT2) 	cd /PATH/TO/NIFTI/$folder
	diffData=$(find . -type f -size +50M -name 'filePrefix*')
       	divisor=2;;

esac

####Convert DICOM to NIFTI####
if [ $format = "dcm" ]
then

	##Set path for dcm2nii##
	dcm2niipath='/PATH/TO/MRICRON/FOLDER/mricron_lx'
	$dcm2niipath/dcm2nii $dicompath

	mv $dicompath/*.bvec $niipath
	mv $dicompath/*.bval $niipath
	rm $dicompath/*.nii.gz
	
	#Split diffusion data into single volumes
	cd $niipath
	diffData=$(find . -type f -size +50M)

	if [[ $diffData != *"nii" ]]
	then
		mv $diffData $diffData".nii"
		diffData=$diffData".nii"
		echo ".nii extension added to file"
	fi
	
	fslsplit $diffData
	
else

	#Split diffusion data into single volumes
	fslsplit $diffData

fi

#Combine (sum) all b0 images to single file
case "$proj" in 

#Example 1 - 10 b0 images to average
PROJECT1) 	fslmaths vol0000.nii.gz -add vol0001.nii.gz -add vol0002.nii.gz -add vol0003.nii.gz -add vol0004.nii.gz -add vol0005.nii.gz -add vol0006.nii.gz -add vol0007.nii.gz -add vol0008.nii.gz -add vol0009.nii.gz sumb0;;

#Example 2 - 2 b0 images to average
PROJECT2) 	fslmaths vol0000.nii.gz -add vol0001.nii.gz sumb0;;

esac

#Make average b0 image
fslmaths sumb0 -div $divisor avgb0

#Remove first b0 and replace with average b0 image
rm vol0000.nii.gz
fslmerge -a dwi_avgb0 avgb0.nii.gz vol00*

#Remove all individual volume files
rm vol00*

#Correct for eddy current distortions
eddy_correct dwi_avgb0 data 0

#Extract brain from skull and create mask image
bet data.nii data_brain -f 0.2 -g 0 -m

#Copy & rename mask to be consistent with bedpostx
cp data_brain_mask.nii.gz nodif_brain_mask.nii.gz

#Create directory to store all files relate to BET but not used for bedpostx
mkdir BETfiles
mv -t BETfiles sumb0.nii.gz avgb0.nii.gz dwi_avgb0.nii.gz data.ecclog data_brain.nii.gz data_brain_mask.nii.gz

#Copy & rename bval and bvec file to be consistent for bedpostx
cp *.bval bvals
cp *.bvec bvecs

#Move all processed files out of raw data folder
mkdir ../$subj'_BET_eddy_correct'
mv -t ../$subj'_BET_eddy_correct' BETfiles bvals bvecs nodif_brain_mask.nii.gz data.nii.gz

#Change to main subject directory
cd ..

#Start bedpostx processing
case "$proj" in 

PROJECT1)	bedpostx $subj'_BET_eddy_correct' -n 2 -w 1 -b 1000 -j 1250 -s 25 -model 2
	mv $subj'_BET_eddy_correct.bedpostX' ../$subj'.bedpostX';;

PROJECT2) 	bedpostx $subj'_BET_eddy_correct' -n 2 -w 1 -b 1000 -j 1250 -s 25 -model 2
	mv $subj'_BET_eddy_correct.bedpostX' ../$subj'.bedpostX';;

esac


