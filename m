#!/bin/bash
#

#  m - Very simple example bash script for using sqlite3
#
#  Copyright (C) 2018 adisezhm@gmail.com
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

init()
{
	sql=sqlite3
	db=eg.sl
	heTbl=hexpense
	return 0;
}

#  get where condition
#
getW()
{
	if [[ $# -eq 0 ]]; then
		f1=date; f1Val=$(date +%Y-%m)
	fi

	if [[ $# -eq 1 ]]; then
		f1=date; f1Val=$1
	fi

	if [[ $# -eq 2 ]]; then
		f1=date; f1Val=$(date +%Y-%m)
		f2=$1;   f2Val=$2
	fi

	if [[ $# -eq 3 ]]; then
		f1=date; f1Val=$1
		f2=$2;   f2Val=$3
	fi

	w1="${f1} like '%${f1Val}%'"
	w2=" and ${f2} like '%${f2Val}%'"
	if [[ ! -z ${f1} ]]; then w=${w1}; fi
	if [[ ! -z ${f2} ]]; then w="${w} ${w2}"; fi

	echo "WHERE : ${w}"

	return 0
}

q()
{
	if [[ $# -lt 0 || $# -gt 3 || $1 = "-h" || $1 = "--help" ]]
	then
		echo "Usage : m q "
		echo "Usage : m q <date>"
		echo "Usage : m q [date] <field> <fieldVal>"
		return 1
	fi

	getW "$@"

	${sql} -bail ${db} << EOQ
.mode column
.headers on
.width 0 0 0 20 32
select rowid, date, amount, category, info from ${heTbl} where ${w} ;
.quit
EOQ

	return $?;
}

qq()
{
	if [[ $# -lt 0 || $# -gt 3 || $1 = "-h" || $1 = "--help" ]]
	then
		echo "Usage : m qq "
		echo "Usage : m qq <date>"
		echo "Usage : m qq [date] <field> <fieldVal>"
		return 1
	fi

	getW "$@"

	${sql} -bail ${db} << EOQ
select sum(amount) from ${heTbl} where ${w}
EOQ

	return $?;
}

qqq()
{
	q "$@"
	if [[ $? -eq 0 ]]; then
		qq "$@"
	fi

	return $?
}

i()
{
	if [[ $# -ne 4 ]]; then
		echo "Usage : i <date> <amount> <category> <info>" >&2
		echo "numArgs: $#" >&2
		return 1;
	fi
	d=$1; a=$2; c=$3; i=$4

	sqlCmd="insert into ${heTbl} (date, amount, category, info) values ('${d}', ${a}, '${c}', '${i}')"
	${sql} ${db} "${sqlCmd}"
	r=$?
	if [[ $r -ne 0 ]]; then
		echo "ERROR: m i : $sqlCmd" >&2
	else
		echo "m i : $sqlCmd"
	fi

	return $?
}

d()
{
	if [[ $# -ne 1 ]]; then
		echo "Usage : d <rowId>" >&2
		echo "numArgs: $#"
		return 1;
	fi
	rowId=$1

	sqlCmd="delete from  ${heTbl} where rowid = $rowId"
	${sql} ${db} "${sqlCmd}"

	return $?
}

u()
{
	if [[ $# -ne 3 ]]; then
		echo "Usage : u <rowId> <field> <fieldVal>" >&2
		return 1;
	fi
	rowId=$1
	field=$2
	fieldVal=$3

	sqlCmd="update ${heTbl} set ${field} = '${fieldVal}' where rowid = ${rowId}"
	echo "m u : ${sqlCmd}"
	${sql} ${db} "${sqlCmd}"

	return $?
}

c()
{
	${sql} ${db} "CREATE TABLE ${heTbl} ( date date, amount float, info text, category text, misc text )"
	return $?
}


iBatch()
{
	r=0
	while read -r date amount cate info
	do
		if [[ -z $date ]]
		then
			continue
		fi
		k=$(echo $info | sed -e 's/^"//' -e 's/"$//')
		m i $date $amount $cate "$k"
		let r=$r+$?
	done

	return $r
}

uniqueCategory()
{
	if [[ $# -gt 2 ]]
	then
		echo "Usage : m uniqueCategory "
		echo "Usage : m uniqueCategory <nolinenum | linenum>"
		echo "Usage : m uniqueCategory <nolinenum | linenum> <date>"
		return 1
	fi

	lineNumOrNot=$1
	if [[ "$lineNumOrNot" = "nolinenum" ]]
	then
		LN=" cat";
	else
		LN="nl"
	fi

	d=$2

	m q ${d} | grep -v -e WHERE -e rowid -e "For" -e '----------' | awk '{ print $4}' | sort -u | ${LN}
	return $?
}

s()
{
	if [[ $# -ne 0 && $# -ne 1 || $1 = "-h" || $1 = "--help" ]]
	then
		echo "Usage : m s "
		echo "Usage : m s <date>"
		return 1
	fi
	d=$1

	#  get and print the where condition
	qqOutput=$(m qq $d); qqOutput="${qqOutput}"
	echo "$qqOutput" | grep WHERE

	#  get the total, for given <date> ie $d
	#  print total, and the header
	total=$(echo "$qqOutput" | tail -n 1 | awk '{ print $1 }' )
	printf "Total : %.0f\n%15s %8s %8s\n" ${total} "category" "amount" "percent"

	#  print summary for each category of expense, for given <date> $d
	cats=$(m uniqueCategory nolinenum ${d})
	for i in ${cats}
	do
		m qq $d category $i | grep -v WHERE | awk -v cat=${i} -v total=${total} '{ printf "%15s %8d %8.2f\n", cat, $1, ($1/total)*100 }'
	done

	return $?
}

init # init globals

if [[ "$1" = "c"   || "$1" = "d"   || "$1" = "i"   || \
      "$1" = "q"   || "$1" = "qq"  || "$1" = "qqq" || \
      "$1" = "u"   || "$1" = "s"                      \
   ]]; then
	cmd=$1
	shift; ${cmd} "$@"; exit $?
fi

if [[ "$1" = "iBatch" || "$1" = "uniqueCategory" ]]; then
	cmd=$1
	shift; ${cmd} "$@"; exit $?
fi
