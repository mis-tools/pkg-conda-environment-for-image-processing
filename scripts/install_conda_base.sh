#!/usr/bin/env bash
set -e 
set -x

miniconda=$1
instdir=$2

#mkdir -p $root/$instdir/lib/
#cd $instdir/lib/

bash $miniconda -b -p $instdir

# from https://www.anaconda.com/blog/changes-to-ancondas-anonymous-usage-data-collection
# so that /opt/conda/etc/aau_token is not generated
#$instdir/bin/conda config --set anaconda_anon_usage off

# remove initial install python version and installed packages
# from: https://stackoverflow.com/questions/52830307/conda-remove-all-installed-packages-from-base-root-environment
$instdir/bin/conda install --revision 0 --yes

#$instdir/bin/conda update -y -n base -c defaults conda
#$instdir/bin/pip install --upgrade pip
