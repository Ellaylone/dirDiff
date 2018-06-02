#! /bin/bash

### Constants
HISTORY_LOCATION="./history"

### Functions

# Выводим помощь по использованию
usage()
{
    echo "usage: dirDiff [[[-w watch] [-d dry] [-i interactive]] | [-h]]"
}

# Дополнительная информация для отладки
showDebugInfo()
{
    echo "DEBUG:"

    echo "watch: $watch"
    echo "interactive: $interactive"
    echo "dry: $dry"

    echo "historyFile: $historyFile"

    echo
    echo "newHistory: ${#newHistory[@]} elements"
    printf "%s\n" "${newHistory[@]}"
    
    echo
    echo "oldHistory: ${#oldHistory[@]} elements"
    printf "%s\n" "${oldHistory[@]}"

    showDiff
}

# Вывод списка изменений
showDiff()
{
    echo
    echo "Diff:"
    printf "%s\n" "${diff[@]}"
}

# Рекурсивное сканирование целевой директории
deepScan()
{
    echo "Scanning..."
    # Для каждого файла в директории переданной в качестве аргумента
    for file in ${1}/*; do
	# Если директория
	if [ -d "$file" ]; then
	    # Добавляем путь к файлу в массив newHistory
	    newHistory+=("$file")
	    # Рекурсивно вызываем deepScan
	    deepScan "${file}"
	else
	    newHistory+=("$file")
	fi
    done
}

# Читает файл истории и записываем значения из него в массив oldHistory
getOldHistory() {
    # Если файл существует
    if [ -e "$historyFile" ]; then
	echo "Scanning old history..."
	# Читаем построчно
	while IFS= read line
	do
	    # Добавляем строку из файла истории в массив oldHistory
	    oldHistory+=("$line")
	done < "$historyFile"
    else
	echo "No history detected."
    fi
}

# Базовый интерактивный режим
runInteractive()
{
    if [ "$interactive" = "1" ]; then
	response=

	# Получаем путь к целевой папке
	echo -n "Enter full path to directory to watch > "
	read response

	if [ -n "$response" ]; then
	    watch=$response
	fi

	# Спрашиваем запуститься ли нам в пробном прогоне
	echo -n "Should dirDiff dry run? (y/n) > "
	read response

	if [ "$response" = "y" ]; then
	    dry=1
	fi
    fi
}

# Функция сравнения истории
compareHistory()
{
    diff=()

    # Получаем список добавленных элементов
    # Для каждого элемента newHistory
    for i in "${newHistory[@]}"; do
	skip=
	# Для каждого элемента oldHistory
	for j in "${oldHistory[@]}"; do
	    # Если находим совпадение - идем к следующему элементу
            [[ $i == $j ]] && { skip=1; break; }
	done
	# Если не нашли совпадений - добавляем элемент в дифф
	[[ -n $skip ]] || diff+=("+ $i")
    done

    # Получаем список удаленных элементов
    # Тот же самый проход по всем элементам, но теперь проверяем наличие элементов из oldHistory в newHistory
    for i in "${oldHistory[@]}"; do
	skip=
	for j in "${newHistory[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
	done
	[[ -n $skip ]] || diff+=("- $i")
    done
}

# Проверка на существование директории для хранения истории
checkForHistoryDir()
{
    # Проверка на существование директории
    if [ -d "$dirname" ]; then
	echo "History directory already exists..."
    else
	echo "History directory does not exist. Creating..."
	# Создание директории
	mkdir -p -- "$dirname"
    fi
}

### Main

interactive=
watch=
dry=
dirname="history"
newHistory=()
oldHistory=()

checkForHistoryDir

# Если запустили без аргументов - покажем инструкцию по использованию
if [ "$1" = "" ]; then
    usage
    exit 1
fi

# Проверяем аргументы и устанавливаем соответствующие им флаги
while [ "$1" != "" ]; do
    case $1 in
	-w | --watch )        shift
			      watch=$1
			      ;;

	-i | --interactive )  shift
			      interactive=1
			      ;;


	-d | --dry )          shift
			      dry=1
			      ;;

	-h | --help )         shift
			      usage
			      exit
			      ;;

	* )                   shift
			      usage
			      exit 1
    esac
    shift
done

# Если получили флаг интерактивного режима - запускаем интерактивный режим
if [ "$interactive" != "" ]; then
    runInteractive
fi

# Если у нас все еще нет пути к папке за которой нужно наблюдать - останавливаем выполнение
if [ "$watch" = "" ]; then
    echo "ERROR: Target directory was not specified"
    exit 1
fi

# Собираем путь к файлу истории
historyFile="${dirname}/${watch##*/}.txt"

getOldHistory

deepScan "${watch}"

compareHistory

# Если не включен пробный режим 
if [ "$dry" != "1" ]; then
    if [ "${#oldHistory[@]}" = "0" ]; then
	echo "Creating new history file..."
    else
	echo "Updating history..."
    fi

    printf "%s\n" "${newHistory[@]}" > ${historyFile}

    showDiff
fi

# Если включен пробный режим - показываем отладочную информацию
if [ "$dry" = "1" ]; then
    showDebugInfo
fi
