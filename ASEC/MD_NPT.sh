#!/bin/bash
#
# Reading information from Infos.dat
#
Project=`grep "Project" Infos.dat | awk '{ print $2 }'`
prm=`grep "Parameters" Infos.dat | awk '{ print $2 }'`
templatedir=`grep "Template" Infos.dat | awk '{ print $2 }'`
tinkerdir=`grep "Tinker" Infos.dat | awk '{ print $2 }'`
gropath=`grep "GroPath" Infos.dat | awk '{ print $2 }'`
multichain=`grep "MultChain" Infos.dat | awk '{ print $2 }'`
step=`grep "Step" Infos.dat | awk '{ print $2 }'`
charge=`grep "Init_Charge" Infos.dat | awk '{ print $2 }'`
relaxpr=`grep "Relax_protein" Infos.dat | awk '{ print $2 }'`
moldy=`grep "MD_ensemble" Infos.dat | awk '{ print $2 }'`
amber=`grep "AMBER" Infos.dat | awk '{ print $2 }'`



echo ""
echo " 

This is the fourth step of APEC and the first step 
in the Molecular Dynamics portion of the protocol. 

In this step, I will find the optimal volume to run the next step of the dynamics. 

Firstly, I will need to set up and keep other parameters - Number of atoms (N), Pressure (P) 
and Temperature (T) constant. To do this, I will need your input specifying the values 
for the duration of the three phases of the MD and the Temperature parameter.

The Molecular dynamics will be run in three subsequent phases:

1. Heating: In this phase I will increase the temperature of the whole system 
   (i.e. protein + solvent in solvent box) slowly to a target temperature. 

2. Equilibration: Equilibration is the point when the properties of the system no longer change with time. 
   To get to that point, in this phase I will set up the NPT system to ensure complete equilibrium across the solvent box. 
   This will remove the errors caused by adding the solvent and ions to the protein sytem in the previous step, 
   and make the solvent box’s molecular properties even. 
   This phase will also relax the system and establish the volume for the next MD step.
    
3. Production:
    In this phase, I will allow the protein environment to move randomly at the target temperature 
    for sometime and collect snapshots of this motion for further calculations. 
    

To do all these, I will ask you:

1. For a target temperature (a.k.a. Production temperature) to heat the system to. 
   It is usually 300 Kelvin. 

2. For a timespan for the heating. Usually 300 picoseconds.

3. For a timespan for equilibration. Usually 2000 picosenconds.

4. For a timespan for production. 
   For this NPT step, I will not need production data, so this will be 0. 

5. If you would like to use GPUs. 
   This is important because of the time this calculation could take. 

You will need to wait till this finishes before running the next script. 

N.B:

1. To check if this simulation is still running, use the squeue -u username  command.
2. This step is only available for the first iteration of APEC i.e. Step_0, 
   because afterwards, the Volume parameter is established.
   
"
echo "Would you like to proceed? [y/n]"
echo ""
read proceed

if [[ $proceed == "y" ]]; then
   echo " Ok, I will now run MD_NPT.sh"
   echo ""
else
   echo " Terminating ..."
   echo ""
   exit 0
fi

cd Dynamic

#
# Colecting the files needed to run the NPT molecular Dynamics
#
if [[ $step -eq 0 ]]; then
   if [[ $moldy == "NVT" ]]; then
      mkdir Sim_NPT     
      cp $templatedir/ASEC/dynamic_sol_NPT.mdp Sim_NPT
      cp Minimization/final-${Project}_box_sol.gro Sim_NPT/${Project}_box_sol.gro
      cp Minimization/${Project}_box_sol.ndx Sim_NPT
      cp Minimization/*.itp Sim_NPT
      cp Minimization/${Project}_box_sol.top Sim_NPT
      cp -r Minimization/$amber.ff Sim_NPT
      cp Minimization/residuetypes.dat Sim_NPT
#      cp ../new_charges Sim_NPT
      cd Sim_NPT
#
# The ESPF charges need to be updated here
#
#      base=`grep -n "; residue   1 CHR rtp CHR" ${Project}_Other_chain_A2.itp | cut -d : -f 1`
#      numchr=`grep -c " 1    CHR " ${Project}_Other_chain_A2.itp`
#      for i in $(seq 1 $numchr); do
#         charge=`head -n $(($base+$i)) ${Project}_Other_chain_A2.itp | tail -n1 | awk '{ print $7 }'`
#         newcharge=`head -n $i new_charges | tail -n1 | awk '{ print $1 }'`
#         sed -i "$(($i+$base))s/$charge/$newcharge/" ${Project}_Other_chain_A2.itp
#      done
   else
      echo "re-do this section ..."
      exit 0
#      cp $templatedir/ASEC/dynamic_sol_NPT.mdp .
#      cp Minimization/final-${Project}_box_sol.gro ${Project}_box_sol.gro
#      cp Minimization/*.itp .
#      cp Minimization/${Project}_box_sol.ndx .
#      cp Minimization/${Project}_box_sol.top .
   fi
fi
if [[ $relaxpr == y ]]; then
   sed -i "s/;freezegrps = GroupDyna/freezegrps = GroupDyna/g" dynamic_sol_NPT.mdp
   sed -i "s/;freezedim = Y Y Y/freezedim = Y Y Y/g" dynamic_sol_NPT.mdp
else
   sed -i "s/;freezegrps = non-Water/freezegrps = non-Water/g" dynamic_sol_NPT.mdp
   sed -i "s/;freezedim = Y Y Y/freezedim = Y Y Y/g" dynamic_sol_NPT.mdp
fi
#else
#   cd Dynamic
#   sed -i "s/;freezegrps = GroupDyna/freezegrps = GroupDyna/g" dynamic_sol_NPT.mdp
#   sed -i "s/;freezedim = Y Y Y/freezedim = Y Y Y/g" dynamic_sol_NPT.mdp
#fi

#
# Defining parameters for the MD
#
echo ""  
echo ""  
echo "********************************************************************"
echo ""  
echo " What is the PRODUCTION TEMPERATURE of the NPT simulation? (Kelvin)"
echo ""
read tempmd
echo ""
#echo " Do you want to heat the system before the MD production run? (y/n)"
#echo
#read risposta
risposta="y"
if [[ $risposta == y ]]; then
   echo ""
   echo " How long is the HEATING PHASE? (ps). Normally use 300."
   echo ""
   read timeheat
   echo ""
   echo " How long is the EQUILIBRATION PHASE? (ps). Normally use 2000."
   echo ""
   read timequi
   echo ""  
else
   timeheat=0
   timequi=0
fi
echo " How long is the production phase? (ps). Normally 0." 
echo " We do not need production data ate this time."
read timeprod
echo ""  

if [[ $risposta == y ]]; then
   numsteps=$(($timeheat+$timequi+$timeprod))
   sed -i "s/TIME1/$timeheat/" dynamic_sol_NPT.mdp
   sed -i "s/TEMP1/$tempmd/g" dynamic_sol_NPT.mdp
else
   numsteps=$timeprod
   sed -i "s/annealing/;annealing/" dynamic_sol_NPT.mdp
   sed -i "s/;gen_vel/gen_vel/" dynamic_sol_NPT.mdp
   sed -i "s/;gen_temp/gen_temp/" dynamic_sol_NPT.mdp
#   sed -i "s/;gen_temp/gen_temp/" dynamic.mdp
   sed -i "s/ref_t = 0/;ref_t = 0/" dynamic_sol_NPT.mdp
   sed -i "s/;ref_t = TEMP1/ref_t = TEMP1/" dynamic_sol_NPT.mdp
   sed -i "s/TEMP1/$tempmd/g" dynamic_sol_NPT.mdp
fi
numsteps=$(($numsteps*1000))
sed -i "s/PASSI/$numsteps/" dynamic_sol_NPT.mdp

#
# Run in the CPUs or GPUs
#
gpu="b"
while [[ $gpu != "y" && $gpu != "n" ]]; do
   echo ""
   echo ""
   echo " Do you want to use the GPUs to compute the dynamics? (y/n)"
   echo ""
   read gpu
done

if [[ $gpu == y"" ]]; then
   cp $templatedir/gromacs.slurm_GPU.sh gromacs.sh
else
   cp $templatedir/gromacs.slurm.sh gromacs.sh
fi

$gropath/gmx grompp -maxwarn 2 -f dynamic_sol_NPT.mdp -c ${Project}_box_sol.gro -n ${Project}_box_sol.ndx -p ${Project}_box_sol.top -o ${Project}_box_sol.tpr

sed -i "s|NOMEPROGETTO|${Project}_box_sol|" gromacs.sh
sed -i "s|NOMEDIRETTORI|$PWD|" gromacs.sh
sed -i "s|GROPATH|$gropath|" gromacs.sh

TMPFILE=`mktemp -d /scratch/photon_XXXXXX`
../../update_infos.sh "tempdir" $TMPFILE ../../Infos.dat
sed -i "s|TEMPFOLDER|$TMPFILE|" gromacs.sh
cp -r * $TMPFILE
current=$PWD
cd $TMPFILE
sbatch gromacs.sh
cd $current

#
# Message to user
#

if [[ $moldy == "NVT" ]]; then
   cd ../../
   cp $templatedir/ASEC/MD_NVT.sh .
   cp $templatedir/Analysis_MD.sh .
   echo ""
   echo "**************************************************************"
   echo ""
   echo " Wait for the NPT molecular dynamics to end then run MD_NVT.sh"
   echo ""
   echo "**************************************************************"
   ./update_infos.sh "Heat_NPT" $timeheat Infos.dat
   ./update_infos.sh "Equi_NPT" $timequi Infos.dat
   ./update_infos.sh "Prod_NPT" $timeprod Infos.dat
   ./update_infos.sh "Next_script" "MD_NVT.sh" Infos.dat
else
   cd ../
   cp $templatedir/ASEC/MD_ASEC.sh .
   cp $templatedir/Analysis_MD.sh .
   echo ""
   echo "***************************************************************"
   echo ""
   echo " Wait for the NPT molecular dynamics to end then run MD_ASEC.sh"
   echo ""
   echo "***************************************************************"
   ./update_infos.sh "HeatMD" $timeheat Infos.dat
   ./update_infos.sh "EquiMD" $timequi Infos.dat
   ./update_infos.sh "ProdMD" $timeprod Infos.dat
   ./update_infos.sh "Next_script" "MD_ASEC.sh" Infos.dat
fi

