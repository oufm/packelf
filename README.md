`packelf` was inspired by [the idea of Klaus D](https://askubuntu.com/a/546305). It is used to package the elf executable and its dependent libraries into a single executable.



## usage

```
packelf.sh <ELF_SRC_PATH> <DST_PATH> [ADDITIONAL_LIBS ...]
```



## example

```
~ # packelf.sh `which perf` /root/perf
~ # /root/perf --version
perf version 3.10.0-1160.49.1.el7.x86_64.debug
```

