#!/bin/sh

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright 2024 Code Construct

set -eu

: "${ENVSUBST:="$(command -v envsubst)"}"
: "${SPONGE:="$(command -v sponge)"}"

checklist_derive_path_from_slug()
{
	checklist_root="$1"
	checklist_slug="$2"
	checklist_file="${checklist_slug}.md"
	echo "${checklist_root}"/"${checklist_file}"
}

checklist_derive_slug_from_path()
{
	checklist_root="$1"
	checklist_path="$2"
	basename "$checklist_path" .md
}

checklist_get_parameters()
{
	checklist_path="$1"
	grep -F '[parameter]: # ' "$checklist_path" | sed -E 's/\[parameter\]: # //'
}

execution_generate_datetime()
{
	date +%YY%mm%dd%HH%MM
}

execution_derive_slug_from_components()
{
	execution_datetime="$1"
	execution_label="$2"
	echo "${execution_datetime}"/"${execution_label}"
}

execution_derive_path_from_slug()
{
	execution_root="$1"
	execution_slug="$2"
	echo "${execution_root}/${execution_slug}.md"
}

execution_derive_slug_from_path()
{
	execution_root="$1"
	execution_path="$2"
	execution_slug="$(realpath --relative-to="$execution_root" "$execution_path")"
	echo "$(dirname "$execution_slug")/$(basename "$execution_slug" .md)"
}

execution_get_substitutions()
{
	execution_path="$1"
	for pn in $(checklist_get_parameters "$execution_path")
	do
		set +u
		eval "p=\$$pn"
		set -u
		[ -z "$p" ] || printf "$%s," "$pn";
	done
}

help()
{
	script="$0"

	printf "%s: Checklist maintenance and execution\n" "$script"
	echo
	printf Subcommands:
	echo
	printf "\tadd NAME\n"
	printf "\t\tEdit and track a new checklist named NAME\n"
	echo
	printf "\tbackup TARGET\n"
	printf "\t\tPush the tracked checklists and executions to the remote git\n"
	printf "\t\trepository TARGET\n"
	echo
	printf "\tedit NAME\n"
	printf "\t\tEdit an existing checklist identified by NAME\n"
	echo
	printf "\thelp\n"
	printf "\t\tShow help text\n"
	echo
	printf "\tlist <checklists | executions>\n"
	printf "\t\tList checklists or executions\n"
	echo
	printf "\tpromote EXECUTION CHECKLIST\n"
	printf "\t\tLift the execution identified by EXECUTION to a checklist named\n"
	printf "\t\tCHECKLIST for reuse\n"
	echo
	printf "\tshow <checklist | execution | parameters> NAME\n"
	printf "\t\tOutput a checklist or execution identified by NAME\n"
	echo
	printf "\t\tIn the case of 'parameters', show the variables that can be\n"
	printf "\t\tsubstituted into the checklist from the environment\n"
	echo
	printf "\trename CURRENT NEW\n"
	printf "\t\tRename a checklist identified by CURRENT to NEW\n"
	echo
	printf "\trun EXECUTION [CHECKLIST ...]\n"
	printf "\t\tExecute a task, guided by zero or more checklists\n"
}

loge()
{
	{ echo "$*" | fold -s; } 2<&1
	return 1
}

main()
{
	name="$0"
	script="$(command -v "$name" | xargs realpath)"
	root="$(dirname "$(dirname "$script")" )"
	checklists="${root}/checklists"
	executions="${root}/executions"

	cd "${root}"

	if [ $# -eq 0 ]
	then
		help "$name"
		exit 0
	fi

	subcmd="$1"
	shift
	case "$subcmd" in
	add)
		[ $# -ge 1 ] ||
			loge \'add\' subcommand requires a checklist name

		checklist_slug="$1"
		checklist_path="$(checklist_derive_path_from_slug "$checklists" "$checklist_slug")"

		[ ! -f "${checklist_path}" ] ||
			loge Checklist path \'"$checklist_path"\' does not exist

		mkdir -p "${checklists}"
		"$EDITOR" "$checklist_path" || ( rm -f "${checklist_path}" && false )
		( git add "$checklist_path" && git commit ) || ( git restore --staged "$checklist_path" && rm "$checklist_path" && false )
		;;

	backup)
		[ $# -ge 1 ] ||
			loge \'backup\' subcommand requires a target name

		target="$1"
		git push "$target" main
		;;

	edit)
		[ $# -ge 1 ] ||
			loge \'edit\' subcommand requires a checklist name

		checklist_slug="$1"
		checklist_path="$(checklist_derive_path_from_slug "$checklists" "$checklist_slug")"

		[ -f "$checklist_path" ] ||
			loge Checklist path \'"$checklist_path"\' does not exist

		( "$EDITOR" "$checklist_path" && git commit "$checklist_path" ) || ( git restore "$checklist_path" && false )
		;;

	help)
		help "$name"
		;;

	list)
		[ $# -ge 1 ] ||
			loge \'list\' subcommand requires an argument of either \'checklists\' or \'executions\'

		category="$1"
		case "$category" in
		checklists)
			[ -d "$checklists" ] ||
				loge No checklists have yet been added

			find "$checklists" -type f |
				while read -r cl
				do
					checklist_derive_slug_from_path "$checklists" "$cl"
				done | sort
			;;
		executions)
			[ -d "$executions" ] ||
				loge No checklists have yet been executed

			find "$executions" -type f |
				while read -r ex
				do
					execution_derive_slug_from_path "$executions" "$ex"
				done | sort
			;;
		esac
		;;

	promote)
		[ $# -ge 2 ] ||
			loge \'promote\' subcommand requires both an execution name and a checklist name as positional arguments

		execution_slug="$1"
		checklist_slug="$2"
		execution_path="$(execution_derive_path_from_slug "$executions" "$execution_slug")"
		checklist_path="$(checklist_derive_path_from_slug "$checklists" "$checklist_slug")"

		[ -f "$execution_path" ] ||
			loge Execution path \'"$execution_path"\' does not exist

		[ ! -f "$checklist_path" ] ||
			loge Checklist path \'"$checklist_path"\' already exists

		mkdir -p "$checklists"
		sed -E 's/^( *)- \[x\]/\1- [ ]/' "$execution_path" > "$checklist_path" || ( rm -f "$checklist_path" && false )
		git add "$checklist_path" && git commit -m "checklists: promote $execution_slug to $checklist_slug"
		;;

	show)
		[ $# -ge 2 ] ||
			loge \'show\' subcommand requires two positional arguments, one of either \'checklist\' or \'execution\', followed by the name of the document to show

		category="$1"
		case "$category" in
		checklist)
			checklist_slug="$2"
			cat "$(checklist_derive_path_from_slug "$checklists" "$checklist_slug")"
			;;
		execution)
			execution_slug="$2"
			cat "$(execution_derive_path_from_slug "$executions" "$execution_slug")"
			;;
		parameters)
			checklist_slug="$2"
			checklist_get_parameters "$(checklist_derive_path_from_slug "$checklists" "$checklist_slug")"
			;;
		esac
		;;

	rename)
		[ $# -ge 2 ] ||
			loge \'rename\' subcommand requires two positional arguments, the current \(source\) name of the checklist to rename, followed by the desired \(destination\) name

		src_checklist_slug="$1"
		dst_checklist_slug="$2"
		src_checklist_path="$(checklist_derive_path_from_slug "$checklists" "$src_checklist_slug")"

		[ -f "$src_checklist_path" ] ||
			loge The source checklist path \'"$src_checklist_path"\' does not exist

		dst_checklist_path="$(checklist_derive_path_from_slug "$checklists" "$dst_checklist_slug")"

		[ ! -f "$dst_checklist_path" ] ||
			loge The destination checklist path \'"$dst_checklist_path"\' already exists

		git mv "$src_checklist_path" "$dst_checklist_path" && git commit -m "checklists: Rename $dst_checklist_slug"
		;;

	run)
		# Allow for ephemeral checklists by only requiring an execution label
		[ $# -ge 1 ] ||
			loge \'run\' command requires an execution name

		execution_label="$1"
		shift
		checklist_slugs="$*"
		execution_datetime="$(execution_generate_datetime)"
		execution_slug="$(execution_derive_slug_from_components "$execution_datetime" "$execution_label")"
		execution_path="$(execution_derive_path_from_slug "$executions" "$execution_slug")"
		for slug in $checklist_slugs; do [ -f "$(checklist_derive_path_from_slug "$checklists" "$slug")" ]; done

		[ ! -f "$execution_path" ] ||
			loge Execution path \'"$execution_path"\' already exists

		execution_dir="$(dirname "$execution_path")"
		mkdir -p "$execution_dir"
		for slug in $checklist_slugs
		do
			printf "\n[comment]: # %s\n" "$slug"
			cat "$(checklist_derive_path_from_slug "$checklists" "$slug")"
		done > "$execution_path"

		execution_substitutions="$(execution_get_substitutions "$execution_path")"
		# shellcheck disable=SC2094
		"$ENVSUBST" "$execution_substitutions" < "$execution_path" | "$SPONGE" "$execution_path" > /dev/null

		"$EDITOR" "$execution_path" || ( rm "$execution_path" && rmdir "$execution_dir" && false )
		git add "$execution_path" && git commit -m "executions: Capture $execution_slug"
		;;

	*)
		help "$name"
		;;
	esac
}

main "$@"
