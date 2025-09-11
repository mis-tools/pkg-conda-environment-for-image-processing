#!/usr/bin/env bash
set -e 
set -x

script_dir=$(dirname "$0")
cd ${script_dir}/..

conda_env_name="conda-environment-for-image-processing"

deb_root="debian"
conda_conf_file=scripts/${conda_env_name}_clean.yml
conda_output_env_file=${conda_env_name}_pinned.yml
${script_dir}/setup_conda_env.sh ${deb_root} ${conda_conf_file} ${conda_output_env_file}

cp ${conda_output_env_file} approved_files/${conda_env_name}_pinned.yml

# two phases needed because using env file _clean.yml and _pinned.yml does not
# produce files with same md5sums (package management conf files).
conda_conf_file=approved_files/${conda_env_name}_pinned.yml
conda_output_env_file=${conda_env_name}_installed.yml
rm -rf /opt/conda
${script_dir}/setup_conda_env.sh ${deb_root} ${conda_conf_file} ${conda_output_env_file}
# TODO: maybe this can be done by:
# mark all packages as installed using env file, instead of only the once in _clean
# if this is not done, the to md5sums of the json files are not the same when using
# update_pkgs_in_conda_env.sh vs builddeb.sh
# $conda env update -f ${conda_output_env_file}

# TODO: replace rsync with direct placement, see readme TODOs
rsync -axHAX /opt ${deb_root}/
# the following is not used because it makes /opt/miniconda/miniconda3/bin/conda first line be
# /usr/bin/env python and we actually want it to be /opt/miniconda/miniconda3/bin/python
# or else when execution sudo /opt/miniconda/miniconda3/bin/conda and error is reported
##fakechroot fakeroot chroot $root $instdir/bin/pip install conda-pack
#fakechroot fakeroot chroot $root $instdir/bin/conda pack -p /opt/miniconda/miniconda3
#dst=${deb_root}/opt/miniconda/miniconda3
#mkdir -p $dst
#tar -xzf $root/miniconda3.tar.gz --directory $dst

# generate debian/DEBIAN/md5sums
${script_dir}/generate_dpkg_md5sums.sh ${deb_root}

md5sum_subset_file=${conda_env_name}.md5sums_without_pyc_and_history
${script_dir}/md5sum_subset_extract.sh ${deb_root}/DEBIAN/md5sums ${md5sum_subset_file}
# validate that files have not changed
approved_md5sum_subset_file=approved_files/${md5sum_subset_file}

set +e
diff -s ${approved_md5sum_subset_file} ${md5sum_subset_file}
diff -s approved_files/${conda_env_name}_installed.yml ${conda_output_env_file}
set -e
# TODO: stop here if not different

# approve files
echo "to approve files execute:"
# cp ${conda_output_env_file} approved_files/${conda_env_name}_installed.yml
# cp ${md5sum_subset_file} ${approved_md5sum_subset_file}
echo cp -a mounts/builddir/conda-environment-for-image-processing_installed.yml mounts/builddir/conda-environment-for-image-processing.md5sums_without_pyc_and_history approved_files/
