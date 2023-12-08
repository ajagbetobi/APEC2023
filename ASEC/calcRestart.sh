Project=`grep "Project" ../Infos.dat | awk '{ print $2 }'`
username=$(whoami) 



echo ""
echo " 

In this script I will continue calculations that crashed for various reasons. 

I will ask which calculation you would like to continue and based on your selection 
I will create a backup of the calculation's folder, then continue the calculation 
in the original folder. 

"
 
echo "Would you like to proceed? [y/n]"
echo ""
read proceed

if [[ $proceed == "y" ]]; then
   echo "
   "
   echo " Ok, I will now run calcRestart.sh"
   echo "
   
      "
else
   echo " Terminating ..."
   echo ""
   exit 0
fi

restartCalc () {
    calctype="$1"

    if [[  $(grep -iq "Happy landing!" "${Project}_${calctype}/${Project}_${calctype}.out") ]];then 
        echo ""
        echo "This calculation is Converged."
        echo ""
        echo "Check ${Project}_${calctype}/${Project}_${calctype}.out"
        echo ""
        exit 0
    fi
   



    # Is there a backup Folder for the calculation?
    isThereAbackup=$(find . -name "*${calctype}_Backup*" -type d)

    
    # If theres no folder with CalculationType_Backup in the Name 
    if [[ -z "${isThereAbackup}" ]];then 

        #create backup 1.
        mkdir ${Project}_${calctype}_Backup_1
    else 

        # If there is get the one with the highest number at the end
        highestBackup=$(ls -1d *${calctype}_Backup* | tail -1)

        # save the number 
        lastBackupNo=${highestBackup: -1}

        # Add 1 to the number, then create a backup folder with new number at the end
        newBackupNo="$((${lastBackupNo}+1))"
        mkdir "${Project}_${calctype}_Backup_${newBackupNo}"

    fi


    highestBackup=$(ls -1d *${calctype}_Backup* | tail -1)

    # Copy Folder to Highest Numbered Backup
    cd ${Project}_${calctype}
    cp -r * ../${highestBackup}

    # Delete all in Folder
    rm -rf * 

    # Copy Select files from backup  
    cp ../${highestBackup}/{amber99sb.prm,molcas-job.sh,${Project}_${calctype}.input,${Project}_${calctype}.JobIph_new,${Project}_${calctype}.Espf.Data,${Project}_${calctype}.key} .
    cp ${Project}_${calctype}.JobIph_new ${Project}_${calctype}.JobIph

    # Go to Latest backup folder 
    cd ../${highestBackup}

    # Search for Latest Calculation Final File and copy to main folder
    highestFile=$(ls -1v *.Final.xyz_* | tail -1)
    cp ${highestFile} ../${Project}_${calctype}/${Project}_${calctype}.xyz

    # Return to main folder
    cd ../${Project}_${calctype}
    sbatch molcas-job.sh
    squeue -u "${username}"

}

echo "

What calculation do you want to continue? [y/n]

1. VDZ Optimization
2. VDZP  Optimization


"

read calculation



if [[ $calculation == "1" ]]; then

    restartCalc "VDZ_Opt"

elif [[ $calculation == "2" ]]; then
    
    restartCalc "VDZP_Opt"
    
else
    exit
fi


