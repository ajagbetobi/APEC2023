#!/bin/bash
#SBATCH -J NOMEPROGETTO
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -t 23:59:00
#SBATCH --mem=16G 
#SBATCH -p qGPU48
#SBATCH --gres=gpu:V100:1
#SBATCH -A CHEM9C4
#SBATCH -e %J.err
#SBATCH -o %J.out
#SBATCH --exclude=acidsgcn007
#--------------------------------------------------------------#

#module load gromacs
module load singularity

export Project=$SLURM_JOB_NAME
export WorkDir=/scratch/$USER/$SLURM_JOB_ID
export InpDir=NOMEDIRETTORI
export outdir=NOMEDIRETTORI/output
echo $SLURM_JOB_NODELIST > $InpDir/nodename
echo $SLURM_JOB_ID > $InpDir/jobid
mkdir $outdir
mkdir -p $WorkDir
#-------------------------------------------------------------#
# Start job
#-------------------------------------------------------------#
cp $InpDir/* $WorkDir
cd $WorkDir
singularity run --nv -B$WorkDir:$WorkDir /sysapps/singularity_images/gromacs_2022.3.sif gmx mdrun -nt 16 -s $Project.tpr -o $Project.trr -x $Project.xtc -c final-$Project.gro -nb gpu
cp $WorkDir/* $outdir/

rm -r $WorkDir

