#!/bin/bash

####Notes & Comments####
help() {
echo ""
echo "Automated Pipeline for (FSL) Probtrackx using Masks in Native Space"
echo "Daniel Elbich"
echo "Cogntive, Aging, and Neurogimaging Lab"
echo "Created: 1/22/19"
echo ""
echo ""
echo " Pipeline which creates seeds, masks, and waypoints for individual"
echo " subjects and conducts probabilistic tractography via probtrackx."
echo " Each script can be run individually."
echo ""
echo " Enter single subject ID followed by the project. If left blank user will be"
echo " prompted to enter IDs."
echo ""
echo ""
echo "Updated: 1/30/19"
echo "Added case gates to switch between project specific data paths."
echo ""
echo "Updated: 2/15/19"
echo "Revised to be single subject input rather than multi. Added flags for subject"
echo "and project information, and also opt out of automativally running"
echo "probtrackx."
echo ""
echo ""
echo "Usage:"
echo "sh automatedDTIProcessingPipeline.sh --subj <subjectID> --proj <projectName> --folder <nameOfFolder> --format <typeOfData>"
echo ""
echo " Required arguments:"
echo ""
echo "	    --subj          Subject ID (no spaces)"
echo "	    --proj          Project name (no spaces)"
echo "      --folder        Directory of raw diffusion data (Optional if --noclean is used)"
echo "      --format        Data format (i.e. dcm, nii) (Optional if --noclean is used)"
echo ""
echo " Optional arguments (You may optionally specify one or more of): "
echo ""
echo "      --noclean     Will not run cleaning/bedpostx functions"
echo "      --noprob      Will not run probtrackx"
echo "      --tract       Read in list of tracts to run"
echo ""
echo ""
exit 1
}
[ "$1" = "--help" ] && help

#Debug code
#automatedDTIProcessingPipeline.sh --subj test123 --proj abc123 --noclean --noprob --folder 017 --format dcm

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
--noclean) clean="$1"
shift # past argument
;;
--noprob) prob="$1"
shift # past argument
;;
--folder) folder="$2"
shift # past argument
shift # past value
;;
--format) format="$2"
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

pipelineDir=/PATH/TO/fsl-diffusion-pipeline

#Cleaning script
if [ "$clean" = "--noclean" ]
then
	echo "Bedpostx skipped..."
else
	echo "Beginning "$subj" data cleaning..."
	sh $pipelineDir/preprocessBedpostData.sh --subj $subj --folder $folder --proj $proj --format $format
fi

#Script to get diffusion to MNI space transformation
echo "Beginning "$subj" MNI Transformation..."
sh $pipelineDir/mniTransform.sh --subj $subj --proj $proj

#Script to fit seeds & waypoints from MNI to diffusion space
echo "Fitting Seeds & Masks to "$subj" subject space..."
sh $pipelineDir/transformSeedsWaypointsTargets.sh --subj $subj --proj $proj

#Probtrackx execution
if [ "$prob" = "--noprob" ]
then
	echo "Probtrackx skipped..."
else
	echo "Starting tracking of "$subj"..."
	sh $pipelineDir/tractography.sh --subj $subj --proj $proj --tract $tract
fi

