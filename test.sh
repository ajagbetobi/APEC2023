# Is there a backup?

isThereAbackup=$(find . -name "traj*" -type d)

if [[ -z "${isThereAbackup}" ]];then 

# If theres no folder with Backup in the Name , create backup 1.
        mkdir traj_1
else 

# If there is get the one with the highest number at the end
    highestBackup=$(ls -1d *traj* | tail -1)

    # cut the number and add 1
    lastBackupNo=${highestBackup: -1}

    # create a backup with name +1
    newBackupNo="$((${lastBackupNo}+1))"
    mkdir "traj_${newBackupNo}"
fi





