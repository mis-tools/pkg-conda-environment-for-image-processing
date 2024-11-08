#!/usr/bin/env bash
set -ex
script_dir=$(dirname "$0")
cd ${script_dir}/..

docker_img_name=build-env_`basename $(git remote show -n origin | grep Fetch | cut -d: -f2-) .git`
echo "building docker image: ${docker_img_name}"
docker build -t ${docker_img_name} scripts/docker_build_environment
# added --net=host to avoid curl error because of wrong mtu - see: https://github.com/moby/moby/issues/22297

rm -rf mounts
mkdir -p mounts/builddir mounts/opt downloads

#gitrev=`git rev-parse HEAD | cut -b 1-8`
#echo "gitrev=$gitrev"
gitrevfull=$(git rev-parse HEAD)
gitrevnum=`git log --oneline | wc -l | tr -d ' '`
echo "gitrevfull=$gitrevfull" > mounts/builddir/git_vars
echo "gitrevnum=$gitrevnum" >> mounts/builddir/git_vars

rm -rf *.deb
docker run -i --rm -u `id -u`:`id -g` -h ${HOSTNAME}-docker --net=host -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v $(pwd)/mounts/opt:/opt -v $(pwd)/mounts/builddir:/builddir -v $(pwd)/scripts:/builddir/scripts -v $(pwd)/approved_files:/builddir/approved_files -v $(pwd)/downloads:/builddir/downloads ${docker_img_name} /builddir/scripts/builddeb.sh $@
mv mounts/builddir/*.deb .
#docker run -it -u `id -u`:`id -g` -h ${HOSTNAME}-docker --net=host -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v $(pwd)/mounts/opt:/opt -v $(pwd)/mounts/builddir:/builddir  -v $(pwd)/scripts:/builddir/scripts -v $(pwd)/approved_files:/builddir/approved_files -v $(pwd)/downloads:/builddir/downloads ${docker_img_name} bash
