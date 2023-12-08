#!/bin/bash
#
# Reading data from Infos.dat
#
Project=`grep "Project" Infos.dat | awk '{ print $2 }'`
Step=`grep "Step" Infos.dat | awk '{ print $2 }'`
templatedir=`grep "Template" Infos.dat | awk '{ print $2 }'`
chain=`grep "RetChain" Infos.dat | awk '{ print $2 }'`
lysnum=`grep "LysNum" Infos.dat | awk '{ print $2 }'`
prm=`grep "Parameters" Infos.dat | awk '{ print $2 }'`
MultChain=`grep "MultChain" Infos.dat | awk '{ print $2 }'`
solvent=`grep "SolventBox" Infos.dat | awk '{ print $2 }'`
uphess=`grep "Update_hessian" Infos.dat | awk '{ print $2 }'`
moldy=`grep "MD_ensemble" Infos.dat | awk '{ print $2 }'`
updch=`grep "Update_charges" Infos.dat | awk '{ print $2 }'`
ions=`grep "Added_Ions" Infos.dat | awk '{ print $2 }' | awk '{print substr ($0, 0, 1)}'`
amber=`grep "AMBER" Infos.dat | awk '{ print $2 }'`


echo ""
echo " 

In this script, I will collect, create and organise all files and folders 
necessary to run another iteration of the APEC protocol - including a folder 
for the next iteration.

As part of this process, I will update the charges of the chromophore in the 
protein by including the information from the new_rtp file created in the last 
script in the aminoacids.rtp file.

**********NOTE:**********

In the iterations after the first (named Step_1 onwards), I  copy selected scripts 
run in Step_0 and use different scripts, as I will run a shorter version of APEC in the following steps. 

This is because, in Step_0 I started with a clean slate and had to describe the system. 
For every Step afterwards, this is not the case.

So in Step_1, I will use the information from Step_0 - such as the MD_NPT results - to run APEC in Step_1. 

For every iteration after Step_0, I will repeat the cycle of using the results of previous iterations as 
starting points for APEC. So, be conscious of your inputs as they will affect future Steps.

"
 
echo "Would you like to proceed? [y/n]"
echo ""
read proceed

if [[ $proceed == "y" ]]; then
   echo "
   "
   echo " Ok, I will now run Next_Iteration.sh"
   echo "
   
   "
else
   echo " Terminating ..."
   echo ""
   exit 0
fi


if [ -d ../Step_$(($Step+1)) ]; then
      echo " Folder \"Step_$(($Step+1))\" found! Something is wrong ..."
      echo " Terminating ..."
      exit 0
      echo ""
fi

mkdir ../Step_$(($Step+1))
mkdir ../Step_$(($Step+1))/Dynamic
./update_infos.sh "Next_script" "MD_NVT.sh" Infos.dat
cp Infos.dat ../Step_$(($Step+1))
./update_infos.sh "Step" $(($Step+1)) ../Step_$(($Step+1))/Infos.dat
cp Next_Script.sh ../Step_$(($Step+1))
cp update_infos.sh $prm.prm template_* ../Step_$(($Step+1))
cp -r Chromophore ../Step_$(($Step+1))
cp $templatedir/ASEC/MD_NVT.sh ../Step_$(($Step+1))
cp $templatedir/ASEC/dynamic_sol_NVT.mdp ../Step_$(($Step+1))/Dynamic
cp $templatedir/gromacs.sh ../Step_$(($Step+1))/Dynamic
cp -r $templatedir/$amber.ff ../Step_$(($Step+1))/Dynamic
#cp ../Step_$(($Step+1))/Dynamic/$amber.ff/normalamino-h ../Step_$(($Step+1))/Dynamic/$amber.ff/aminoacids.hdb
#cp ../Step_$(($Step+1))/Dynamic/$amber.ff/amino-rettrans ../Step_$(($Step+1))/Dynamic/$amber.ff/aminoacids.rtp
cat calculations/ESPF_charges/new_rtp >> ../Step_$(($Step+1))/Dynamic/$amber.ff/aminoacids.rtp  
cp calculations/new_charges ../Step_$(($Step+1))
cp calculations/${Project}_VDZP_Opt/${Project}_VDZP_Opt.JobIph_new ../Step_$(($Step+1))/${Project}_VDZP_Opt.JobIph_old
cp calculations/${Project}_finalPDB/${Project}_new.gro ../Step_$(($Step+1))/Dynamic/${Project}_box_sol.gro
cp Dynamic/${Project}_box_sol.top ../Step_$(($Step+1))/Dynamic
cp Dynamic/${Project}_box_sol.ndx ../Step_$(($Step+1))/Dynamic
cp Dynamic/residuetypes.dat ../Step_$(($Step+1))/Dynamic
cp Dynamic/*.itp ../Step_$(($Step+1))/Dynamic

echo ""
echo " *******************************************************"
echo ""    
echo " Go to Step_$(($Step+1)) and continue with \"MD_NVT.sh\""
echo ""
echo " *******************************************************"

