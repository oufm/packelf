`packelf` was inspired by [the idea of Klaus D](https://askubuntu.com/a/546305). It is used to pack a ELF program and its dependent libraries into a single executable file.


## usage

```
Usage: ./packelf.sh [-zjJn] <ELF_SRC_PATH> <DST_PATH> [ADDITIONAL_LIBS ...]
      -zjJ    compress flag passed to tar, '-z' by default
      -n      pack without compress
```

First, pack a ELF program. For example, you can pack `ls` like this:

```
# ./packelf.sh /bin/ls /root/ls
tar: Removing leading `/' from member names
'/bin/ls' was packed to '/root/ls'
Just run '/root/ls ARGS...' to execute the command.
Or run 'PACKELF_UNPACK_DIR=xxx /root/ls' to unpack it only.
```

You can execute the packed program directly:

```
# /root/ls -lh /root/ls 
-rwxr-xr-x 1 root root 1.3M May 21 08:35 /root/ls
```

However, every time the packed program is executed, an internal unpacking operation is performed automatically, which results in a slower startup of the program.

If you need to execute the program many times and want to reduce the startup time, you can unpack the program before executing it.

```
# Run the packed program directly, it takes longer.
~ # time bash -c 'for i in {1..100};do /root/ls >/dev/null; done'
real    0m4.203s
user    0m2.067s
sys     0m3.093s

# You can unpack it first.
~ # PACKELF_UNPACK_DIR=/usr/local/bin /root/ls
'ls' was unpacked to '/usr/local/bin'.
You can run '/usr/local/bin/ls ARGS...' to execute the command.

# ls and ls.res are generated after unpacking.
~ # /usr/local/bin/ls -lh /usr/local/bin/ls*
-rwxr-xr-x 1 root root 3.9K May 21 09:00 /usr/local/bin/ls
/usr/local/bin/ls.res:
total 3.0M
-rwxr-xr-x 1 root root 175K May 21 09:00 ld-linux-x86-64.so.2
-rwxr-xr-x 1 root root 2.0M May  3  2022 libc.so.6
-rw-r--r-- 1 root root  15K May  3  2022 libdl.so.2
-rw-r--r-- 1 root root 454K Feb  3  2018 libpcre.so.3
-rwxr-xr-x 1 root root 142K May  3  2022 libpthread.so.0
-rw-r--r-- 1 root root 152K Mar  1  2018 libselinux.so.1
-rwxr-xr-x 1 root root 131K Jan 18  2018 ls

# Running the unpacked launch script (/usr/local/bin/ls) will take much less time.
~ # time bash -c 'for i in {1..100};do /usr/local/bin/ls >/dev/null; done'
real    0m0.370s
user    0m0.239s
sys     0m0.133s
```

## dependence
* sh
* tar
* sed
* grep
* chmod
* readlink
* ldd (only needed for packing, not needed for executing or unpacking)

Note: If your tar doesn't support gzip, '-n' is needed when you pack a program.
