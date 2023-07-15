#!/bin/bash
#SBATCH -J NOMEPROGETTO
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -t 120:00:00
#SBATCH --mem-per-cpu=4GB
#SBATCH -p qCPU120
#SBATCH -A CHEM9C4
#SBATCH -e %J.err
#SBATCH -o %J.out
#SBATCH --exclude=acidsgcn007

module load gromacs

export Project=$SLURM_JOB_NAME
export WorkDir=/scratch/$SLURM_JOB_ID
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
gmx mdrun -nt 16 -s $Project.tpr -o $Project.trr -x $Project.xtc -c final-$Project.gro
cp $WorkDir/* $outdir/

rm -r $WorkDir

