`packelf` was inspired by [the idea of Klaus D](https://askubuntu.com/a/546305). It is used to package the elf executable and its dependent libraries into a single executable.

## usage

```
packelf.sh <ELF_SRC_PATH> <DST_PATH> [ADDITIONAL_LIBS ...]
```

Requirements on the machine: `touch`, `tar`, `sh` and `mktemp`

```
packelf-kf.sh <ELF_SRC_PATH> <DST_PATH> [ADDITIONAL_LIBS ...]
```

Requirements on the machine: `tar`, `sh` and `mkdir`

This other version doens't extract everytime the package if already exists.
Perfect for tiny packages.

## how works

Generate a tar that include all the llibraries from the host, with a tiny shell script embedded use LS Preload to execute the program.

## example

```
~ # packelf.sh `which perf` /root/perf
~ # /root/perf --version
perf version 3.10.0-1160.49.1.el7.x86_64.debug
```

Repository with CI that generate a release with the zip package automatically: https://github.com/Mte90/yad-static-build
