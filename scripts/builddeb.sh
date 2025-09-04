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
conda_conf_file=approved_files/${conda_env_name}_installed.yml
conda_output_env_file=${conda_env_name}_reinstalled.yml
${script_dir}/setup_conda_env.sh ${deb_root} ${conda_conf_file} ${conda_output_env_file}

# generate debian/DEBIAN/md5sums
${script_dir}/generate_dpkg_md5sums.sh ${deb_root}

md5sum_subset_file=${conda_env_name}.md5sums_without_pyc_and_history
${script_dir}/md5sum_subset_extract.sh ${deb_root}/DEBIAN/md5sums ${md5sum_subset_file}
# validate that files have not changed
approved_md5sum_subset_file=approved_files/${md5sum_subset_file}
diff -s ${approved_md5sum_subset_file} ${md5sum_subset_file}
rm ${md5sum_subset_file}

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
