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

q()
{
	month=$1
	if [[ $# -eq 0 ]]; then
		month=$(date +%Y-%m)
	fi

	${sql} -bail ${db} << EOQ
.mode column
.headers on
.width 0 0 0 0 32
.print For date : ${month}
select rowid, date, amount, category, info from ${heTbl} where date like '%${month}%';
.quit
EOQ

	return $?;
}

qq()
{
	if [[ $# -ne 0 && $# -ne 1 && $# -ne 2 ]]
	then
		echo "Usage : m qq " 
		echo "Usage : m qq <date>" 
		echo "Usage : m qq <field> <fieldVal>" 
		return 1
	fi

	if [[ $# -eq 0 ]]; then
		field=date
		fieldVal=$(date +%Y-%m)
	fi

	if [[ $# -eq 1 ]]; then
		field=date
		fieldVal=$1
	fi

	if [[ $# -eq 2 ]]; then
		field=$1
		fieldVal=$2
	fi

	echo -e "For date : ${fieldVal}   \c"
	${sql} -bail ${db} << EOQ
select sum(amount) from ${heTbl} where ${field} like '%${fieldVal}%'
EOQ

	return $?;
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

c()
{
	${sql} ${db} "CREATE TABLE ${heTbl} ( date date, amount float, info text, category text, misc text )"
	return $?
}

init # init globals

if [[ "$1" = "c" || "$1" = "d" || "$1" = "i" || "$1" = "q" || "$1" = "qq" ]]; then
	cmd=$1
	shift; ${cmd} "$@"; exit $?
fi
