# ZFS

## Домашнее задание

1. Определить алгоритм с наилучшим сжатием.
Шаги:
определить какие алгоритмы сжатия поддерживает zfs (gzip gzip-N, zle lzjb, lz4);
создать 4 файловых системы на каждой применить свой алгоритм сжатия;
2. Определить настройки pool’a.
Шаги:
загрузить архив с файлами локально.
с помощью команды zfs import собрать pool ZFS;
командами zfs определить настройки: размер хранилища; тип pool; значение recordsize; какое сжатие используется; какая контрольная сумма используется.
3. Найти сообщение от преподавателей.
Шаги:
скопировать файл из удаленной директории.
Файл был получен командой zfs send otus/storage@task2 > otus_task2.file
восстановить файл локально. zfs receive
найти зашифрованное сообщение в файле secret_message

## 1. Определить алгоритм с наилучшим сжатием

Работа выполняется на виртуальной машине, созданной из Vagrantfile от имени root.

Выведем список всех дисков:

```bash
[root@zfs ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk 
sdc      8:32   0  512M  0 disk 
sdd      8:48   0  512M  0 disk 
sde      8:64   0  512M  0 disk 
sdf      8:80   0  512M  0 disk 
sdg      8:96   0  512M  0 disk 
sdh      8:112  0  512M  0 disk 
sdi      8:128  0  512M  0 disk 

```

Создаем из имеющихся дисков 4 пула в режиме RAID1:

```bash
[root@zfs ~]# zpool create otus1 mirror /dev/sd{b,c}
[root@zfs ~]# zpool create otus2 mirror /dev/sd{d,e}
[root@zfs ~]# zpool create otus3 mirror /dev/sd{f,g}
[root@zfs ~]# zpool create otus4 mirror /dev/sd{h,i}
[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   106K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   104K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   104K   480M        -         -     0%     0%  1.00x    ONLINE  -

```

Добавим разные алгоритмы сжатия и проверим:

```bash
[root@zfs ~]# zfs set compression=lzjb otus1
[root@zfs ~]# zfs set compression=lz4 otus2
[root@zfs ~]# zfs set compression=gzip-9 otus3
[root@zfs ~]# zfs set compression=zle otus4
[root@zfs ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local

```

Скачаем один файл во все пулы:

```bash
[root@zfs ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2022-11-18 13:31:22--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40875295 (39M) [text/plain]
Saving to: '/otus1/pg2600.converter.log'

100%[=====================================================================>] 40,875,295   362KB/s   in 1m 52s 

2022-11-18 13:33:16 (356 KB/s) - '/otus1/pg2600.converter.log' saved [40875295/40875295]
...
[root@zfs ~]# ls -l /otus*
/otus1:
total 22033
-rw-r--r--. 1 root root 40875295 Nov  2 08:36 pg2600.converter.log

/otus2:
total 17980
-rw-r--r--. 1 root root 40875295 Nov  2 08:36 pg2600.converter.log

/otus3:
total 10952
-rw-r--r--. 1 root root 40875295 Nov  2 08:36 pg2600.converter.log

/otus4:
total 39947
-rw-r--r--. 1 root root 40875295 Nov  2 08:36 pg2600.converter.log

```

Посмотрим размер данного файла в разных пулах:

```bash
[root@zfs ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.5M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.1M   313M     39.0M  /otus4

```

По выводу команды видно, что наилучшая степень сжатия в пуле otus3, т.е при использовании алгоритма gzip-9.

## 2. Определить настройки pool’a

Скачиваем архив в домашний каталог и разархивируем его:

```bash
[root@zfs ~]# wget -O archive.tar.gz --no-check-certificate ‘https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download
...
2022-11-18 13:48:57 (378 KB/s) - 'archive.tar.gz' saved [7275140/7275140]
[1]+  Done                    wget -O archive.tar.gz --no-check-certificate https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
[root@zfs ~]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

```

Посмотрим данные пула :

```bash
[root@zfs ~]# zpool import -d zpoolexport
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

 otus                         ONLINE
   mirror-0                   ONLINE
     /root/zpoolexport/filea  ONLINE
     /root/zpoolexport/fileb  ONLINE

```

Импортируем данный пул на нашу систему:

```bash
`[root@zfs ~]# zpool import -d zpoolexport/ otus
[root@zfs ~]# zpool status
  pool: otus
 state: ONLINE
  scan: none requested
config:

 NAME                         STATE     READ WRITE CKSUM
 otus                         ONLINE       0     0     0
   mirror-0                   ONLINE       0     0     0
     /root/zpoolexport/filea  ONLINE       0     0     0
     /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

```

Теперь посмотрим размер хранилища пула:

```bash
[root@zfs ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

```

Определим тип пула:

```bash
[root@zfs ~]# zfs get type otus
NAME  PROPERTY  VALUE       SOURCE
otus  type      filesystem  -

```

Посмотрим настройки рекомендуемого размера блока для файлов в ФС:

```bash
[root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

```

Тип сжатия выведем следующей командой:

```bash
[root@zfs ~]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local

```

Тип контрольной суммы:

```bash
[root@zfs ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

```

## 3. Найти сообщение от преподавателей

Копируем файл из удаленной директории и восстанавливаем на локальной системе:

```bash
[root@zfs ~]# wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&e xport=download
...
[1]+  Done                    wget -O otus_task2.file --no-check-certificate https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
[root@zfs ~]# zfs receive otus/test@today < otus_task2.file

```

Ищем зашифрованное сообщение в файле secret_message и находим ссылку на github:

```bash
[root@zfs ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome

```
