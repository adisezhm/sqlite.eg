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
	month=$1
	if [[ $# -eq 0 ]]; then
		month=$(date +%Y-%m)
	fi

	${sql} -bail ${db} << EOQ
.print For date : ${month}
select sum(amount) from ${heTbl} where date like '%${month}%'
EOQ

	return $?;
}

i()
{
	if [[ $# -ne 4 ]]; then
		echo "Usage : i <date> <amount> <info> <category>"
		echo "numArgs : $#"
		return 1;
	fi
	d=$1; a=$2; i=$3; c=$4

	sqlCmd="insert into ${heTbl} (date, amount, info, category) values ('${d}', ${a}, '${i}', '${c}')"
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
