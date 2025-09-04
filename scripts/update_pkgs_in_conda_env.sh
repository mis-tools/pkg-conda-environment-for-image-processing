#!/usr/bin/env bash
set -e 
set -x

script_dir=$(dirname "$0")
cd ${script_dir}/..

conda_env_name="conda-environment-for-image-processing"

deb_root="debian"
conda_conf_file=scripts/${conda_env_name}_clean.yml
conda_output_env_file=${conda_env_name}_installed.yml
${script_dir}/setup_conda_env.sh ${deb_root} ${conda_conf_file} ${conda_output_env_file}

diff -s approved_files/${conda_env_name}_installed.yml $conda_output_env_file
