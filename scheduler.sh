#!/bin/bash

function submit_stage () {
    cd $2/pipelines/$1
    echo "#!/bin/bash"$'\n'"dvc repro dvc.yaml" > auto_generated_job_$1.sh
    sargs="-J $1 -A snic2021-1-2 -N 1 -t $3 --exclusive"
    if [ -z "$4" ]
    then
        stdout=$(sbatch $sargs auto_generated_job_$1.sh)
    else
        stdout=$(sbatch $sargs --dependency=afterok:$( echo "${@:4}" | tr " " "," ) auto_generated_job_$1.sh)
    fi
    id=${stdout##* }
    printf -v "${1}" '%s' "${id}"
    rm auto_generated_job_$1.sh
    cd $2
}

if [[ $1 == '--custom-stage' ]]
then
    echo submit_stage ${@:2}
    exit 0
fi

CWD=$(realpath $(dirname "${BASH_SOURCE[0]}"))
# run tracmass
# TODO stage="tracmass"; submit_stage $stage $CWD "7-00:00:00"
# convert to hdf5
# TODO stage="to_hdf5"; submit_stage $stage $CWD "7-00:00:00" $tracmass
# add columns
stage="indomain"; submit_stage $stage $CWD "3-00:00:00" # $to_hdf5
stage="initime"; submit_stage $stage $CWD "3-00:00:00" # $to_hdf5
stage="iswall"; submit_stage $stage $CWD "3-00:00:00" # $to_hdf5
stage="depth"; submit_stage $stage $CWD "7-00:00:00" # $to_hdf5
# stage="temperature"; submit_stage $stage $CWD "0-00:30:00" # $to_hdf5
# stage="salinity"; submit_stage $stage $CWD "0-00:30:00" # $to_hdf5
# add secondary columns
stage="maxage"; submit_stage $stage $CWD "5-00:00:00" $initime
stage="mindepth"; submit_stage $stage $CWD "5-00:00:00" $depth
# add indices
# TODO stage="spgi"; submit_stage $stage $CWD "0-01:00:00" $initime
# TODO stage="naoi"; submit_stage $stage $CWD "0-01:00:00" $initime
# TODO stage="eapi"; submit_stage $stage $CWD "0-01:00:00" $initime
# TODO stage="lwdi"; submit_stage $stage $CWD "0-01:00:00" $initime
# TODO stage="jeti"; submit_stage $stage $CWD "0-01:00:00" $initime
