#!/usr/bin/echo This script needs to be sourced, not run directly: source

#
# Handle the most common python venv operations automatically
# Will try in order:
# 	- Deactivate current venv if one is active
#	- Activate venv in current directory
#	- Search directories upwards for venvs and activate them
#	- Ask to create a new venv in current directory
#		- If requirements.txt is detected, ask if you want to install dependencies
#

venv_name=".venv"

venv_search() {
	current=$PWD
	while [[ -n "$current" ]] ; do
		result=$(find "$current" -maxdepth 1 -type d -name "$venv_name")
		if [[ -n $result ]]; then
			return 0;
		fi
		current=$(echo "$current" | rev | cut -f 2- -d '/' | rev)
	done
	return 1
}

if type deactivate > /dev/null 2> /dev/null; then
	echo "Leaving venv"
	deactivate
elif venv_search; then
	relpath=$(realpath --relative-to='.' "$result")
	dir_name="\e[1m$(echo -n "$result" | rev | cut -f 2 -d '/' | rev)\e[0m"
	string="Activating existing venv for $dir_name"
	if [[ $relpath != "$venv_name" ]]; then
		string="$string ( $relpath )"
	fi
	echo -e "$string"
	source "$result"/bin/activate
else
	echo -n "Create new venv? (Y/n): "
	read -r ans
	if [[ "$ans" != N* && "$ans" != n* ]]; then
		echo "Creating new venv"
		prompt=$(realpath . | rev | cut -f 1 -d '/' | rev)
		python3 -m venv "$venv_name" --prompt "\e[96m$prompt\e[0m"
		source "$venv_name"/bin/activate

		if ls requirements.txt > /dev/null 2> /dev/null; then
			echo -n "Install requirements in new venv? (Y/n): "
			read -r ans
			if [[ "$ans" != N* && "$ans" != n* ]]; then
				pip install -r requirements.txt
			fi
		fi
	else
		echo "Doing nothing"
	fi
fi
