#!/usr/bin/env bash
set -e 
set -x

miniconda=$1
instdir=$2

#mkdir -p $root/$instdir/lib/
#cd $instdir/lib/

sh $miniconda -b -p $instdir

# remove initial install python version and installed packages
# from: https://stackoverflow.com/questions/52830307/conda-remove-all-installed-packages-from-base-root-environment
$instdir/bin/conda install --revision 0  

#$instdir/bin/conda update -y -n base -c defaults conda
#$instdir/bin/pip install --upgrade pip
