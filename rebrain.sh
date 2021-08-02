#!/bin/bash

function timestamp() {
  date '+%H:%M:%S'
}
# функция проверки аргументов
function arg() {
yes=0
array=( "-p" "-c" "-m" "-d" "-n" "-la" "-k" "-o" "-h" "--proc" "--cpu" "--memory" "--disks" "---network" "--loadaverage" "--kill" "--output" "--help" )
for i in ${array[@]}; do
  if [[ "$1" = $i ]]; then
   yes=1
    break
  fi
done
}

# функция предложения возпользоваться help
function usage() {
  echo "Usage: $0 -h or --help, for more information"
}
# функция вызова данных help
function showhelp() {
cat <<  EOF
Usage: $(basename $0) [options] [parameter]
Options:
-p, --proc - работа с директорией /proc
-c, --cpu - работа с процессором
-m, --memory - работа с памятью
-d, --disks - работа с дисками
-n, --network - работа с сетью
-la, --loadaverage - вывод средней нагрузки на систему
-k, --kill - отправка сигналов процессам (простой аналог утилиты kill)
-o, --output - сохранение результатов работы скрипта на диск
-h, --help - справочная информация
EOF
exit 0
}

# функция аргумента -p, --proc
function proc() {
arg $1 #проверяем следущий аргумент
if [[ -z $1 ]] || [[  $yes == 1 ]] # проверка на наличие аргумента и что это аргумент из списка
then ls /proc ; sft=1 # выводит листинг директории /proc
elif [[ -f /proc/$1 ]] # проверка наличие файла
then cat /proc/$1 ; sft=2 # выводит содержимое указанного файла из директории /proc
else 
echo "$0: Bad option: $1 Usage: [-p | --proc] [-p "namefile"] " ; exit 1
fi
}

function ios() {
  if [[ -f /bin/iostat ]] # проверка на существование ifstat
  then iostat
  else
  echo "not install sysstat" exit 1
  fi
}


# функция аргумента -c, --cpu
function cpu() {
arg $1 
if [[ -z $1 ]] || [[ $yes == 1 ]]
then ios -c ; sft=1 # вывод информации об использовании процессора
elif [[ $1 == "top10" ]]
then  ps aux | sort -nk +3 | tail -10; sft=2 # вывод топ 10 процессов
elif [[ $1 == "user" ]]
then echo $(timestamp && (ios -c | awk 'NR == 4 { print $1} ')); sft=2 # процент использования процессора программами, запущенными на уровне пользователя
elif [[ $1 == "wait" ]]
then echo $(timestamp && (ios -c | awk 'NR == 4 { print $4} ')); sft=2 # процент времени затраченного на ожидание завершения операций ввода/вывода
else 
echo "$0: Bad option: -c $1 Usage: [-c | --cpu] [-c top10] [-c user] [-c wait] " ; exit 1
fi
}
# функция аргумента -m, --memory
function memory() {
arg $1
if [[ -z $1 ]] || [[ $yes == 1 ]]
then free ; sft=1 # вывод free
elif [[ $1 == "total" ]]
then echo $(timestamp && (cat /proc/meminfo | grep MemTotal | awk '{ print $2 }')); sft=2 # всего доступно физической памяти на сервере
elif [[ $1 == "available" ]]
then echo $(timestamp && (cat /proc/meminfo | grep MemAvailable | awk '{ print $2 }')); sft=2 # памяти доступно к использованию
elif [[ $1 == "free" ]]
then echo $(timestamp && (cat /proc/meminfo | grep MemFree | awk '{ print $2 }')); sft=2 # Свободная / Неиспользуемая памят
elif [[ $1 == "used" ]]
then echo $(timestamp && (free | grep Mem | awk '{ print $3 }')); sft=2 # использованная память
else 
echo "$0: Bad option: $1 Usage: [-m | --memory] [-m total] [-m available] [-m free] [-m used] " ; exit 1
fi 
}
# функция аргумента -d, --disks
function disk() {
arg $1 
if [[ -z $1 ]] || [[ $yes == 1 ]]
then lsblk; sft=1 # вывод lsblk
elif [[ $1 == "use" ]]
then echo $(timestamp && (df -h / | grep / | awk '{ print $5}')); sft=2 # процент использованного обьема раздела /
elif [[ $1 == "util" ]]
then  echo $(timestamp && (ios -d -x | awk 'NR == 5 { print $21} ')); sft=2 # процент утилизации диска
elif [[ $1 == "write" ]]
then  echo $(timestamp && (ios -d -x | awk 'NR == 5 { print $8} ')); sft=2 # значение IOPS запись
elif [[ $1 == "read" ]]
then  echo $(timestamp && (ios -d -x | awk 'NR == 5 { print $2} ')); sft=2 # значение IOPS чтение
else 
echo "$0: Bad option: $1 Usage: [-d | --disk] [-d use] [-d util] [-d write] [-d read] "; exit 1
fi
}
# функция утилиты  ifstat
function ifstt() {
  if [[ -f /bin/ifstat ]] # проверка на существование ifstat
  then ifstat -aztS
  else
  echo "not install sysstat" exit 1
  fi
}
# функция аргумента -n, --network
function net() {
arg $1 
if [[ -z $1 ]] || [[ $yes == 1 ]]
then ip a; sft=1 # просмотр ip 
elif [[ $1 == "ifstat" ]]
then  ifstt; sft=2  # мониторинга нагрузки на сетевые интерфейсы
else 
echo "$0: Bad option: $1 Usage: [-n | --network] [ -n ifstat] " ; exit 1
fi
}
# функция аргумента -la, --loadaverage
function load() {
arg $1 
if [[ -z $1 ]] || [[ $yes == 1 ]]
then uptime | awk '{ print $1, $10, $11, $12}' ; sft=1 # вывод средней нагрузки на систему
else
echo "$0: Bad option: $1 Usage: [-la | --loadaverage]" ; exit 1
fi
}
# функция аргумента -k, --kill
function kil() {
arg $1
if [[ -z $1 ]] || [[ $yes == 1 ]]
then  sft=1 ; exit 1
else 
echo "$0: Bad option: $1 Usage: [-k | --kill] [-k "PID"] " ; exit 1
fi
for pid in $(ps -a | awk '{ print $1 }' | sed '$a\END') # составления запущенных списка процессов
do
if [ $1 == $pid ] # если процесс есть в списке
then kill $1 ; sft=2 # завершаем введенный процесс
break
elif [ $pid  == END ] # если нет вс писке выдаем ошибку
then echo "$0: Bad PID: $1" ; sft=2  
break 
fi
done
}
# функция аргумента -o, --output ( первый вариант надо вводит тока  первыым аргументом)
function out() {
arg $1 
if [[ -z $1 ]] || [[ $yes == 1 ]] 
then exec 1>./log ; sft2=1 ; return 1
fi
arg $2
if [[ $1 == "save" ]] && [[ $yes != 1 ]] 
then  exec 1>$2 ; sft2=3 # сохраняет вывод скрипта в файл с перезаписью данных
elif [[ $1 == "rw" ]] && [[ $yes != 1 ]] 
then  exec 1>>$2 ; sft2=3 # сохраняет вывод скрипта в файл c дозаписью данных
else
echo "$0: Bad option: $1 Usage: [-o | --output] [-o save namefile] [-o rw namefile]" ; exit 1
fi
}


# проверка наличия аргументов, если их нет предлает ввести аргумент help
if [[ -z $@ ]] ;
then usage 
exit 1
fi
# проверка на наличие аргумента -o, --output (второй вариант )
#for x in  $*
#do
#if [[ "-o" = $x ]] || [[ "--output" = $x ]] ;
#then exec 1.>>./log ; sft2=1 # сохраняет вывод скрипта в файл
#fi
#done

while (( "$#" ))
do
case "$1" in
    -p|--proc)
     proc $2 
     shift "$sft"
     ;;
    -c|--cpu)
     cpu $2
     shift "$sft"
     ;;
    -m|--memory)
     memory $2 
    shift "$sft"
     ;;
    -d|--disks)
    disk $2
    shift "$sft"
     ;;
    -n|--network)
    net $2
    shift "$sft"
     ;;
    -la|--loadaverage)
    load $2
    shift "$sft"
     ;;
    -k|--kill)
    kil $2
    shift "$sft"
     ;;
    -o|--output)
    out $2 $3
    shift "$sft2"
     ;;
    -h|--help)
    showhelp
    shift
     ;;   
    *)
    usage 
    exit 1
    ;;
  esac
 
  done

