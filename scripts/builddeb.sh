#!/usr/bin/env bash
set -e 
set -x

script_dir=$(dirname "$0")
cd ${script_dir}/..

BUILD_NUMBER=$1
version="1.1.0"

conda_env_name="conda-environment-for-image-processing"
package="pkg-${conda_env_name}"
maintainer="Conda-forge <https://github.com/conda-forge/miniforge/issues>"
arch="all"

deb_root="debian"
rm -rf ${deb_root}
mkdir -p ${deb_root}/DEBIAN

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

Miniforge3_version=25.3.1-0
Miniforge3_file=Miniforge3-${Miniforge3_version}-Linux-x86_64.sh

dwndir=downloads
mkdir -p $dwndir
if [[ ! -f $dwndir/$Miniforge3_file ]]; then
    wget https://github.com/conda-forge/miniforge/releases/download/${Miniforge3_version}/$Miniforge3_file -O $dwndir/$Miniforge3_file
fi

cwd=`pwd`

HOME=/builddir

if [ ! -d $instdir ]; then

./scripts/install_conda_base.sh $dwndir/$Miniforge3_file $instdir

conda=$instdir/bin/conda

conda_conf_file=approved_files/${conda_env_name}_installed.yml
$conda env update -f $conda_conf_file

conda_output_env_file=${conda_env_name}_reinstalled.yml
$conda env export -n base > $conda_output_env_file

# conda doctor reports these missing:
#find root/opt/ -name __pycache__ -exec rm -r {} +
#find root/opt/ -name *.pyc -exec rm {} \;

$conda clean --force-pkgs-dirs --all --yes
# from: https://github.com/conda-forge/miniforge-images/blob/master/ubuntu/Dockerfile

$conda doctor -v

fi
rsync -axHAX /opt ${deb_root}/
# the following is not used because it makes /opt/miniconda/miniconda3/bin/conda first line be
# /usr/bin/env python and we actually want it to be /opt/miniconda/miniconda3/bin/python
# or else when execution sudo /opt/miniconda/miniconda3/bin/conda and error is reported
##fakechroot fakeroot chroot $root $instdir/bin/pip install conda-pack
#fakechroot fakeroot chroot $root $instdir/bin/conda pack -p /opt/miniconda/miniconda3
#dst=${deb_root}/opt/miniconda/miniconda3
#mkdir -p $dst
#tar -xzf $root/miniconda3.tar.gz --directory $dst

echo "Compute md5 checksum."
cwd=$(pwd)
mkdir -p ${deb_root}/DEBIAN
cd ${deb_root}
find . -type f ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -print0 | tr '\0' '\n' | sort | xargs -d '\n' md5sum > DEBIAN/md5sums
cd ${cwd}

# .pyc files are currently not reprodicible, so they are
# excluded from the md5sum validation process
# see: https://github.com/python/cpython/issues/73894 and
# https://github.com/conda/conda-package-handling/issues/1
cat debian/DEBIAN/md5sums | grep -v ".pyc$" | grep -v "conda-meta/history$" > ${conda_env_name}.md5sums_without_pyc_and_history

# approving files by:
# cp $conda_output_env_file approved_files/${conda_env_name}_installed.yml

# validate that files have not changed
# diff -s debian/DEBIAN/md5sums approved_files/md5sums
diff -s approved_files/${conda_env_name}.md5sums_without_pyc_and_history ${conda_env_name}.md5sums_without_pyc_and_history
rm ${conda_env_name}.md5sums_without_pyc_and_history
diff -s approved_files/${conda_env_name}_installed.yml $conda_output_env_file

#date=`date -u +%Y%m%d`
#echo "date=$date"

source /builddir/git_vars

buildtimestamp=`date -u +%Y%m%d-%H%M%S`
hostname=`hostname`
echo "build machine=${hostname}"
echo "build time=${buildtimestamp}"
echo "gitrevfull=$gitrevfull"
echo "gitrevnum=$gitrevnum"

debian_revision="${gitrevnum}"
upstream_version="${version}"
echo "upstream_version=$upstream_version"
echo "debian_revision=$debian_revision"

packageversion="${upstream_version}-git${debian_revision}"
packagename="${package}_${packageversion}_${arch}"
echo "packagename=$packagename"
packagefile="${packagename}.deb"
echo "packagefile=$packagefile"

description="build machine=${hostname}, build time=${buildtimestamp}, git revision=${gitrevfull}"
if [ ! -z ${BUILD_NUMBER} ]; then
    echo "build number=${BUILD_NUMBER}"
    description="$description, build number=${BUILD_NUMBER}"
fi

installedsize=`du -s ${deb_root} | awk '{print $1}'`

mkdir -p ${deb_root}/DEBIAN/
#for format see: https://www.debian.org/doc/debian-policy/ch-controlfields.html
cat > ${deb_root}/DEBIAN/control << EOF |
Section: science
Priority: extra
Maintainer: $maintainer
Version: $packageversion
Package: $package
Architecture: $arch
Installed-Size: $installedsize
Description: $description
EOF

echo "Creating .deb file: $packagefile"
rm -f ${package}_*.deb
fakeroot dpkg-deb -Zxz --build ${deb_root} $packagefile

echo "Package info"
dpkg -I $packagefile
