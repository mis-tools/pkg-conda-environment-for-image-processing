# how to update packages

Inspired by: [ContinuumIO miniconda3 docker-image](https://github.com/ContinuumIO/docker-images/blob/main/miniconda3/debian/Dockerfile)

## build package

```bash
rm -rf build && ./scripts/build_using_docker.sh
# fails if packages have been updated
cp build/conda_environment_development_installed.yml md5sums_without_pyc_and_history approved_files/
./scripts/build_using_docker.sh
```

## diff and commit

```bash
git status
git diff approved_files/conda_environment_development_installed.yml approved_files/md5sums_without_pyc_and_history scripts/conda_environment_development_clean.yml

git add approved_files/conda_environment_development_installed.yml approved_files/md5sums_without_pyc_and_history scripts/conda_environment_development_clean.yml
git commit...
git push
```

## TODOs

* replace rsync in builddeb.sh line 91 with something like:

  ```bash
  mv $root/opt ${deb_root}/
  rm -rf $root/*
  ```
* don't delete Miniconda installer every time, dwn to git root dir and rsync to build folder
* fix missing .pyc files when running "conda doctor"
* check for "The environment is inconsistent" during creation. Cannot find a official way to check for "The environment is inconsistent" during creation, there does not seem to currently be a cli cmd for this, this must however be fairly easy to implement, found hooks in: [1](https://github.com/conda/conda/blob/3e7595314d85b9aa5a4e4ba3201661cfaaa10b4a/conda/core/solve.py#L632) and [2](https://github.com/search?q=repo%3Aconda%2Fconda%20inconsistent&type=code). I belive it the best would be to make a feature request on the github page regarding this.
* debsums reports some files: find out why, and see if anything can be done about this
* update the conda version in the boot strap root environment
* add rm cmd to uninstall postrm, preinstall script, or something like this, as we should get a completly new environment without old user installed files when installing a new miniconda package
