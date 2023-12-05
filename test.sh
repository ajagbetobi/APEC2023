# If theres no folder with Backup in the Name , create backup 1.


isThereAbackup=$(find . -name "traj*" -type d)

if [[ -z "${isThereAbackup}" ]];then 
        mkdir traj_1
else 
    highestBackup=$(ls -1d *traj* | tail -1)
    lastBackupNo=${highestBackup: -1}
    newBackupNo="$((${lastBackupNo}+1))"
    echo ${newBackupNo}
    mkdir "traj_${newBackupNo}"
fi

# If there is get the last number of the name

# cut it add 1

# create backup with name +1