# fsl-diffusion-pipeline
Pipeline for diffusion data processing and fiber tracking in FSL

Automated scripts for preprocessing diffusion data through FSL bedpostx and probtrackx. Pipeline ```automatedDTIProcessingPipeline.sh``` covers:

```preprocessBedpostData.sh.sh```
Averaging multiple b0 images (if applicable).
Corrects for eddy current distortions.
Runs bedpostx on preprocessed data (default settings).

```mniTransform.sh```
Fits diffusion data to MNI152 (2mm) template to obtain MNI transformation matrix.
Inverts MNI transformation to allow registration of standard MNI regions to subject space.
Output saved within subject directory.

```transformSeedsWaypointsTargets.sh```
Converts standard masks in MNI space to subject space.
Creates waypoints and avoid masks for probtrackx.
Output saved within subject directory.

```tractography.sh```
Runs probtrackx for multiple different tracks (default settings minus curvature value).
Output saves in separate analysis path distinct from raw data.


Each script can be run standalone in case of error or user specific needs (e.g. do not want to run probtackx at the time). Add --help after each script to bring up the help dialog for more information on specific requirements for each script.


```sh automatedDTIProcessingPipeline.sh --subj <subjectID> --proj <projectName> --folder <nameOfFolder> --format <typeOfData>```



Misc

createPBS_scripts
Shell scripts to batch create and run PBS scripts for use with this pipeline
