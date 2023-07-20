#!/bin/bash
#
# Check if Infos.dat already exists in current directory. If so, terminate to avoid overwriting.
#
if [ -f Infos.dat ]; then
   echo ""
   echo " ARM fatal error - Infos.dat exists."
   echo " The new project must start in a folder with no other ARM projects."
   echo " Create a suitable directory, move New_APEC.sh there and run it."
   echo ""
   echo " New_APEC.sh is exists..C_APEC."
   exit 0
fi
echo ""
echo ""
echo ""
echo ""
echo "*****************************************************************************************************"
echo "*****************************************************************************************************"
echo ""
echo "          *         ******     *******      ***            ********  *******    *****                "
echo "         ***       **    **    **         **   **          **        **        **   **               "
echo "        ** **      **    **    **        **                **        **       **                     "
echo "       **   **     ******      ******    **         ***    ******    ******   **  *****              "
echo "      *********    **          **        **                **        **       **     **              "
echo "     **       **   **          **         **   **          **        **        **   **               "
echo "    **         **  **          *******      ***            **        *******    *****                "
echo ""
echo "                            Version 2.0: APEC-FEG for Flavoproteins                                  "
echo ""
echo ""
echo "                                                                 Written by: Yoelvis Orozco-Gonzalez "
echo "                                               with contributions by: M. Pabel Kabir and Samer Gozem "
echo "                                                                 Gozem Lab, Georgia State University "
echo "                                                 Latest version, May 2021 by Yoelvis Orozco-Gonzalez "
echo "*****************************************************************************************************"
echo "*****************************************************************************************************"
echo ""
echo ""
echo ""

#Load/Call on applications APEC procedure will use.
module load openmolcas
module load gromacs

# Define the path of the APEC code installation directory and copy generic Infos.dat file from there to current APEC procedure directory.

camino="/userapp/APEC_Spr2023/New_APEC/template"
cp $camino/Infos.dat .

#
# Ask for the name of the project
#
echo " What is the name of the project (the name MUST not start with a number)??"
read Project
echo ""

#Check if Step_0 (First APEC Iteration) already exists, terminate if so.
if [ -d Step_0 ]; then
      echo " Folder \"Step_0\" found! Something is wrong ..."
      echo " Terminating ..."
      exit 0
      echo ""
fi

#Make Step_0

mkdir Step_0

#
# Find all the PDB files in the current folder.
#
i=1
ext=pdb

# Go through each pdb file in the current directory, add them to a filelist
for f in *.$ext; do
    filelist[$i]=$f
    i=$(($i+1))
done
i=$(($i-1))

#
# Variable len counts how many PDB files are in the folder, len+1 is required for ending
# the while loop smoothly. Here the user is asked to select which PDB file has to be used
#
len=${#filelist[*]}
echo ""
echo " Select within $len files $ext:"
echo " (This should be the pdb file of the protein without the chromophore)"
echo ""
len=$(($len+1))
i=1
while [ $i -lt $len ]; do
      echo " $i: ${filelist[$i]}"
      let i++
done
echo ""
read choice
if [ -z ${filelist[$choice]} ]; then
   echo " Option unavailable. The program is closing..."
   rm -r Step_0
   exit 0
else
   pdbfile=${filelist[$choice]}
   pdb=$(basename $pdbfile .pdb)
   echo " You just selected ${filelist[$choice]}"
   echo ""
fi
cp $pdb.pdb Step_0/${Project}.pdb
if [ -f *.prm ]; then
   cp *.prm Step_0/
fi
mv Infos.dat Step_0/
if [[ -f seqmut ]]; then
   cp Step_0/${Project}.pdb Step_0/wt_${Project}.pdb
   cp seqmut Step_0/
   cp $camino/mutate.sh Step_0/
fi
cd Step_0/

#
# Count the total charge of the protein without the chromophore.
#
plusc=`awk '{ print $4 " " $5 " " $6 }' ${Project}.pdb | uniq | awk '{ if ( $1 == "LYS" || $1 == "HIS" || $1 == "ARG" || $1 == "NA" ) print $1 }' | wc -l`
minusc=`awk '{ print $4 " " $5 " " $6 }' ${Project}.pdb | uniq | awk '{ if ( $1 == "ASP" || $1 == "GLU" || $1 == "CL" || $1 == "ACI" || $1 == "TYO" ) print $1 }' | wc -l`
totcarica=$(($plusc-$minusc))

#
# Check if Infos.dat was copied. Terminate otherwise.
#
if [ -z Infos.dat ]; then
   echo " ARM fatal error! - Infos.dat not found"
   echo " Please check if Infos.dat exists in the ARM installation directory"
   echo " If not, reinstall ARM"
   echo ""
   echo " New.sh is terminating"
   echo ""
   cd ..
   rm -r Step_0
   exit 0

#If it was copied, update the Project key in the Infos.dat file with the value of the project name given by the user.
else
   echo "Project $Project" >> Infos.dat

#Get APEC Installation directory from Infos file and save as templatedir.
   templatedir=`grep "Template" Infos.dat | awk '{ print $2 }'`
fi
#
# Retrieve amber99sb force field parameters from Installation Directory for Tinker.
#
cp $templatedir/amber99sb.prm amber99sb.prm

# Update Infos.dat file with the following key value pairs.

echo "AMBER amber99sb" >> Infos.dat
echo "Parameters amber99sb" >> Infos.dat
echo "CurrCalc Start" >> Infos.dat

cp $templatedir/smooth_restart.sh .

#
# Checking for multiple chains in the PDB file. Write this in Infos.dat for future use.
#
grep 'ATOM' ${Project}.pdb > atoms
nchain=`grep 'TER' ${Project}.pdb | wc -l`
chain=A
if [[ $nchain -eq 1 ]]; then
   multchain=no
else
   multchain=yes
   numends=( $( grep -B1 'TER' ${Project}.pdb | grep 'ATOM' | awk '{ print $6 }' ) )
   numstarts=( $( grep -A1 'TER' ${Project}.pdb | grep 'ATOM' | awk '{ print $6 }' ) )
   ngaps=$(($nchain-1))
   for ((i=0;i<$ngaps;i=$(($i+1)))); do
       lastres[$i]=${numends[$i]}
       diffchain[$i]=$((${numstarts[$i]}-${numends[$i]}-1))
   done
fi

#
# Write chain info in Infos.dat
if [[ $multchain == "yes" ]]; then
   echo "MultChain YES" >> Infos.dat
   echo "LastRes ${lastres[@]}" >> Infos.dat 
   echo "DiffChain ${diffchain[@]}" >> Infos.dat
else
   echo "MultChain NO" >> Infos.dat
fi
#
# Check if a list of residues belonging to the retinal cavity is provided. 
# If it is copy to current directory and update Infos.dat file.
#
if [[ -f ../cavity ]]; then
   answer=b
   while [[ $answer != y && $answer != n ]]; do
         echo " The cavity file has been found! Do you want to use it? (y/n)"
         read answer
         echo ""
   done
   if [[ $answer == y ]]; then
      echo "CavityFile YES" >> Infos.dat
      cp ../cavity .
   else
      echo "CavityFile NO" >> Infos.dat
   fi
else
   echo "CavityFile NO" >> Infos.dat
fi
#
# Checking the first residue number and writing it in Infos.dat
#
startres=`grep 'ATOM' $Project.pdb | head -n 1 | awk '{ print $6 }'`
echo "StartRes $startres" >> Infos.dat
#
# Retrieving non-standard ionization states for future use
#
for restrano in 'ASH' 'GLH' 'HIE' 'HID' 'LYD'; do
    strange=( $( grep " $restrano " $Project.pdb | awk '{ print $6 }' | uniq ) )
    if [[ ${strange[0]} != '' ]]; then
       echo "$restrano ${strange[@]}" >> Infos.dat
    fi
done
#
# Generate wild type PIR sequence by using Modeller
#
modelchk=`grep "Modeller" Infos.dat | awk '{ print $2 }'`
if [[ $modelchk == YES ]]; then
   cp $camino/getpir.py .
   cp $camino/mutate_model.py .
   sed -i "s/PROGETTO/$Project/g" getpir.py
   python getpir.py
   echo ""
fi

#
# Copy the xyz file of the chromophore
#
chromophore="CHR_chain"

if [[ -f ../$chromophore.xyz ]]; then
   echo ""
   echo "$chromophore.xyz will be used"
   echo "chromophore $chromophore" >> Infos.dat
   echo ""
else
   echo ""
   echo " $chromophore.xyz does not exist"
   echo ""
   cd ..
   rm -r Step_0
   exit 0
fi

#
# Define the total charge of the chromophore
#
chr=20
while [[ $chr -ne -4 && $chr -ne -3 && $chr -ne -2 && $chr -ne -1 && $chr -ne 0 && $chr -ne 1 && $chr -ne 2 && $chr -ne 3 && $chr -ne 4 ]]; do
   echo ""
   echo ""
   echo " What is the total charge of the CHROMOPHORE (including the charge of the tail which is normally -2)."
   echo " Just type integer numbers (-1, 0, 1 ...)"
   echo ""
   read chr
done

#
# Add Chromophore atoms to the protein pdb before generating the mutations
#
grep "ATOM  " $Project.pdb > ATOMS
lastatom=`tail -n1 ATOMS | awk '{ print $2 }'`
lastres=`tail -n1 ATOMS | awk '{ print $6 }'`
chratoms=`head -n1 ../$chromophore.xyz`

head -n $(($chratoms+2)) ../$chromophore.xyz | tail -n $chratoms > temp1
awk '{ print $2,"   ",$3,"   ",$4,"   ",$5}' temp1 > xyz


#Fortran Section

cat > format.f << YOE
      Program format
      implicit real*8 (a-h,o-z)
      character label2*2, label5*5

      open(1,file='xyz',status='old')
      open(2,file='HETATM_CHR',status='new')
      do i=1,$chratoms
         read(1,*)x,y,z,label2
         write(2,'(A,i5,2x,A,2x,A,i4,4x,f8.3,f8.3,f8.3)')"HETATM",
     &     $(($lastatom+1))+i,label2,"CHR A",$(($lastres+1)),x,y,z
      enddo
      close(1)
      close(2)
      end
YOE
gfortran format.f -o format.x
./format.x

#Append Heteroatoms in Project pdb to Water and Chromophore Hetero atoms files
grep "HETATM" $Project.pdb > HETATM_wat
grep "HETATM" $Project.pdb >> HETATM_CHR
sed -i "/HETATM/d" $Project.pdb
cat HETATM_CHR >> $Project.pdb

#
# If seqmut is found, the mutation routine is started, given that either Modeller or SCWRL4 is available
# This information is gotten from Infos.dat
#
if [[ -f seqmut ]]; then
   scwrlchk=`grep "SCWRL4" Infos.dat | awk '{ print $2 }'`
   modelchk=`grep "Modeller" Infos.dat | awk '{ print $2 }'`
   if [[ $scwrlchk == YES || $modelchk == YES ]]; then 
      ./mutate.sh $Project $scwrlchk $modelchk
   else
      echo " You don't have any software to perform mutations!"
      echo " Please delete seqmut and try again"
      echo " Aborting..."
      echo ""
      exit 0
   fi
#Search for the mutation error ID in an error file.

   errid=`grep 'mutate_errid' arm.err | awk '{ print $2 }'`
#If it isn't found, output this.
   if [[ $errid -eq 0 ]]; then
      echo " The following mutations has been inserted:"
      cat seqmut
      echo ""
   else
      echo " Problem in mutate.sh, no mutations will be performed."
      echo " Please type y to go on with the wild type, or n to abort"
      read scelta
      echo ""
      case $scelta in
           y) echo " Going on with the wild type..."
              mv wt_${Project}.pdb $Project.pdb
           ;;
           n) echo " Aborting..."
              echo ""
              exit 0
           ;;
      esac
   fi
else
   echo " No mutants requested, going on with the wild type.."
   echo ""
fi
sed -i "/HETATM/d" $Project.pdb
cat HETATM_wat >> $Project.pdb
rm ATOMS temp1 xyz HETATM_wat HETATM_CHR format.x format.f

#
# Recompute the total charge of the protein after generating the mutations.
#
plusc=`awk '{ print $4 " " $5 " " $6 }' ${Project}.pdb | uniq | awk '{ if ( $1 == "LYS" || $1 == "HIS" || $1 == "ARG" || $1 == "NA" ) print $1 }' | wc -l`
minusc=`awk '{ print $4 " " $5 " " $6 }' ${Project}.pdb | uniq | awk '{ if ( $1 == "ASP" || $1 == "GLU" || $1 == "CL" || $1 == "ACI" || $1 == "TYO" ) print $1 }' | wc -l`
totcarica=$(($plusc-$minusc))

#
# Convert the geometry of the chromophore from xyz to pdb for future 
# conversion to gromacs.
#
mkdir Chromophore
cp ../$chromophore.xyz Chromophore
cd Chromophore

numatm=`head -n1 $chromophore.xyz | awk '{ print $1 }'`
end=`grep -n "End\|end\|END" $chromophore.xyz | cut -f1 -d:`


#Fortran Section

cat > write_pdb.f << YOE
      Program write_pdb
      implicit real*8 (a-h,o-z)
      character label*3,opls*8,line30*30

      open(1,file='$chromophore.xyz',status='old')
      open(2,file='$chromophore.pdb',status='unknown')

CCCCCCCCC Number of atoms of the solute
      num=$numatm
CCCCCCCCC
      read(1,*)
      read(1,*)
      do i=1,num
         read(1,*)label,x,y,z,opls
         write(2,'(A,1x,i4,2x,A,1x,A,4x,3(f7.3,1x))')
     &   "HETATM",i,label,"CHR A   1",x,y,z
      enddo
      write(2,*)
      do i=num+3,$end-1
         read(1,'(A)')line30
      enddo
      end
YOE

gfortran write_pdb.f -o write_pdb.x
./write_pdb.x
rm write_pdb.x

#
# Message to the user
#
carga=$(($chr+$totcarica))
if [[ $totcarica != 0 ]]; then
   echo " The system total charge is $carga,"
   echo " which is different than zero"
   echo " Please be sure your PDB file is right"
   echo " Going on..."
   echo ""
else
   echo " The system total charge is $carga,"
   echo " everything seems ok"
   echo ""
fi

cd ..
cp $templatedir/ASEC/update_infos.sh .
./update_infos.sh "Step" "0" Infos.dat
./update_infos.sh "Init_Charge" $carga Infos.dat
./update_infos.sh "Chromo_Charge" $chr Infos.dat
cp $templatedir/NewStep.sh .

#Copy Next_Script from TemplateDir to Step_0 folder
cp $templatedir/Next_Script.sh Step_0/

echo ""
echo ""
echo " ****************************************************"
echo ""
echo " Step_0 Folder created! cd Step_0/, then ./NewStep.sh"
echo ""
echo " ****************************************************"
echo ""

