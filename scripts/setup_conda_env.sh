#!/usr/bin/env bash
set -ex

script_dir=$(dirname "$0")

deb_root=$1
conda_conf_file=$2
conda_output_env_file=$3

rm -rf ${deb_root}
mkdir -p ${deb_root}

# the final build/installed conda contains: cat /opt/miniconda/miniconda3/conda | head -n 1 = /opt/miniconda/miniconda3/bin/conda
# the conda interpreter should be used inside the conda script, else "sudo /opt/miniconda/miniconda3/bin/conda"
# give error: "ImportError: No module named conda.cli" it gives this error because the default os python interpreters PYTHONPATH
# do not contain the conda dir.
# Note: fakechroot is used used so that the conda installer things it is installing it in the same location as it should in the
# deb package, this is done becaue the conda installer writes this path into some of the conda files during installation.
# for more information on this, see: https://groups.google.com/a/continuum.io/forum/#!topic/anaconda/TJBtuWab1DE
# quote from source: You can never copy or move Anaconda and expect things to work. One example why not is that the 
# “shbang” lines #!/path/to/original/bin/python are not updated by a cp or mv operation. The path either will not exist in
# the new location, or the effect of copying it will result in using the “old locations” libraries (etc.).
instdir=/opt/conda

Miniforge3_version=26.1.0-0
Miniforge3_file=Miniforge3-${Miniforge3_version}-Linux-x86_64.sh

dwndir=downloads
mkdir -p $dwndir
if [[ ! -f $dwndir/$Miniforge3_file ]]; then
    wget https://github.com/conda-forge/miniforge/releases/download/${Miniforge3_version}/$Miniforge3_file -O $dwndir/$Miniforge3_file
    # TODO: validate md5sum
fi

# conda needs the HOME to be a writable dir, as it creates $HOME/.conda
HOME=/builddir

if [ ! -d $instdir ]; then

./scripts/install_conda_base.sh $dwndir/$Miniforge3_file $instdir

mamba=$instdir/bin/mamba
conda=$instdir/bin/conda

$mamba env update --yes -f $conda_conf_file

$mamba env export -n base > ${conda_output_env_file}

# conda doctor reports these missing:
#find root/opt/ -name __pycache__ -exec rm -r {} +
#find root/opt/ -name *.pyc -exec rm {} \;

$mamba clean --force-pkgs-dirs --all --yes
# from: https://github.com/conda-forge/miniforge-images/blob/master/ubuntu/Dockerfile

$conda doctor -v

fi
