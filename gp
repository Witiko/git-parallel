#!/bin/bash
# == The initial setup ==
export IFS=

# == Helper functions ==
info() { printf "$1\n" "${@:2}"; }
error() { info "${@}" 1>&2; }
errcat() { cat 1>&2; }

# Print the usage information.
usage() {
	cat <<-'EOF'
Usage:

	EOF
	for CMD in "${SYNOPSES[@]}"; do
		(IFS=' '; for INDEX in $(eval echo '${!'`echo "SYNOPSIS_$CMD"`'[@]}'); do
			SYNOPSIS=$(eval echo '${'`echo "SYNOPSIS_$CMD"`"[$INDEX]}")
			printf '\t%s\n' "$SYNOPSIS"
		done)
	done | sort | uniq
	cat <<'EOF'

To see more information about any individual COMMAND, execute

	gp help COMMAND

Report bugs to: <witiko@mail.muni.cz>
Git-parallel home page: <http://github.com/witiko/Git-parallel>
EOF
}

# Print the version information.
version() {
	echo 'Git-parallel version 1.2.0'
}

# Print help for a specific subcommand.
help() {
	# Guard against empty input.
	[[ $# = 0 ]] && usage && return 0

	# Guard against bad input.
	if [[ ! "$1" =~ ^[[:alpha:]]*$ || ! " ${SYNOPSES[@]} " =~ " $1 " ]]; then
		error "There is no command '%s'." "$1"
		return 1
	fi

	# Perform the main routine.
	(IFS=' '; for INDEX in $(eval echo '${!'`echo "SYNOPSIS_$1"`'[@]}'); do
		SYNOPSIS=$(eval echo '${'`echo "SYNOPSIS_$1"`"[$INDEX]}")
		USAGE=$(eval echo '${'`echo "USAGE_$1"`"[$INDEX]}")
		printf "\n\t%s\n\n%s\n" "$SYNOPSIS" "$USAGE"
	done)
}

# Check if the repository names are admissible.
checkNames() {
	for NAME; do
		if [[ -z "$NAME" ]]; then
			error 'Git-parallel repository names must be non-empty.'
			return 1
		fi
		if [[ "$NAME" =~ [./] ]]; then
			error "The repository name '%s' contains illegal characters (., /)." \
				"$NAME"
			return 2
		fi
		if [[ "$NAME" =~ ^- ]]; then
			error "Git-parallel repository names may not start with a hyphen (-)."
			return 3
		fi
	done
}

# Retrieve the nearest directory containing the directory $1 and change the
# working directory to it.
jumpToRoot() {
	ORIGINAL_PWD="$PWD"
	[[ -d "$1" ]] && return 0
	while [[ $PWD != / ]]; do
		if cd ..; then
			[[ -d "$1" ]] && return 0
		else
			return 1
		fi
	done
	error "No directory '%s' was found in '%s' or its parents." "$1" \
		"$ORIGINAL_PWD"
	return 2
}

# Retrieve the currently active repository.
activeRepository() {
	LINK="`readlink .git`" &&
	[[ "$LINK" =~ ^\.gitparallel/ ]] && printf '%s\n' "${LINK#.gitparallel/}"
}

# Remembering the current repository consists of pushing the contents of the
# .git symlink into the stack.
REMEMBERED=
remember() {
	if [[ -e .git ]]; then
		REMEMBERED="`mktemp -d`" &&
		mv .git "$REMEMBERED"
	fi
}

# Restoring a repository consists of popping a path from the stack and
# switching to the path.
restore() {
	# Perform the main routine.
	rm .git &&
	if [[ -n "$REMEMBERED" ]]; then
		mv "$REMEMBERED"/.git .git &&
		REMEMBERED= &&
		info "Restored the original Git repository in '%s'." "$PWD"
	else
		info "Removed the '.git' symlink from '%s'." "$PWD"
	fi
}

# == Subcommands ==

SYNOPSES+=(init i)
SYNOPSIS_init=('gp {i | init} [-F | --follow-git] [-u | --update-gitignore]')
USAGE_init=(
"creates a new '.gitparallel' directory that is going to serve as the root
directory for the remaining 'gp' commands. When the -F / --follow-git option is
specified, the command will create the '.gitparallel' directory next to the
current Git repository root rather than inside the current working directory.
When the -u / --update-gitignore option is specified, an entry for the
'.gitparallel' will be added to the '.gitignore' file.")
SYNOPSIS_i=("${SYNOPSIS_init[@]}")
USAGE_i=("${USAGE_init[@]}")

init() {
	FOLLOW_GIT=false
	UPDATE_GITIGNORE=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-F)																				;& # fall-through
			--follow-git)				FOLLOW_GIT=true				;;
			-u)																				;& # fall-through
			--update-gitignore)	UPDATE_GITIGNORE=true	;;
			--)																				;; # ignore
			*)									error "An unexpected argument '%s'." "$1"
													return 1							;;
		esac
		shift
	done

	# Guard against bad input.
	$FOLLOW_GIT && ! jumpToRoot .git && return 1
	if [[ -d .gitparallel ]]; then
		error "There already exists a '.gitparallel' directory in '%s'." "$PWD"
		return 2
	fi

	# Perform the main routine.
	mkdir .gitparallel &&
	info "Created a '.gitparallel' directory in '%s'." "$PWD" &&
	if $UPDATE_GITIGNORE; then
		if [[ ! -e .gitignore ]]; then
			printf '.gitparallel\n' >.gitignore
			info "Created a '.gitignore' file."
		else
			if [[ -e .gitignore ]] && ! grep -q '^\.gitparallel' <.gitignore; then
				printf '.gitparallel\n' >>.gitignore
				info "Updated the '.gitignore' file."
			else
				info "No update of the '.gitignore' file was necessary."
			fi
		fi
	fi
}

SYNOPSES+=(list ls)
SYNOPSIS_list=('gp {ls | list} [-p | --porcelain] [-H | --human-readable]')
USAGE_list=(
"lists the available Git-parallel repositories. When the -p / --porcelain
option is specified or when the output of the command gets piped outside the
terminal, a raw newline-terminated list is produced, ready to be used by the
'gp do' command.  When the -H / --human-readable option is specified or when
the output of the command stays in the terminal, a formatted list is produced.")
SYNOPSIS_ls=("${SYNOPSIS_list[@]}")
USAGE_ls=("${USAGE_list[@]}")

if [[ -t 1 ]]; then PIPED=false; else PIPED=true; fi
list() {
	PORCELAIN=$PIPED

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-p)																;& # fall-through
			--porcelain)			PORCELAIN=true	;;
			-H)																;& # fall-through
			--human-readable)	PORCELAIN=false	;;
			--)																;; # ignore
			*)								error "An unexpected argument '%s'." "$1"
												return 1				;;
		esac
		shift
	done

	# Guard against bad input.
	jumpToRoot .gitparallel || return 1

	# Perform the main routine.
	if [[ -d .gitparallel ]]; then
		ACTIVE="`activeRepository`"
		(shopt -s nullglob
		for REPO in .gitparallel/*/; do
			REPO=${REPO##.gitparallel/}
			REPO=${REPO%%/}
			printf '%s%s%s\n' "`if ! $PORCELAIN; then
				if [[ "$REPO" = "$ACTIVE" ]]; then
					printf '* \033[32m'
				else
					printf '  '
				fi
			fi`" "$REPO" "`$PORCELAIN || printf '\033[m'`"
		done)
	fi
}

SYNOPSES+=(create cr)
SYNOPSIS_create=('gp {cr | create} [-m | --migrate] REPO...')
USAGE_create=(
'creates new Git-parallel REPOsitories. When the -m / --migrate option is
specified, the REPOSITORies are initialized with the contents of the currently
active Git repository.')
SYNOPSIS_cr=("${SYNOPSIS_create[@]}")
USAGE_cr=("${USAGE_create[@]}")

create() {
	REPOS=()
	MIGRATE=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-m)												;& # fall-through
			--migrate)	MIGRATE=true	;;
			--)												;; # ignore
			*)					REPOS+=("$1")	;;
		esac
		shift
	done
	
	# Guard against bad input.
	$MIGRATE && ! GIT_ROOT="`jumpToRoot .git && printf '%s\n' "$PWD"`" && exit 1
	jumpToRoot .gitparallel || return 2
	if [[ "${#REPOS[@]}" = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		return 3
	fi
	! checkNames "${REPOS[@]}" && return 4
	for REPO in "${REPOS[@]}"; do
		if [[ -d .gitparallel/"$REPO" ]]; then
			error "The Git-parallel repository '%s' already exists." "$REPO"
			return 5
		fi
	done

	# Perform the main routine.
	for REPO in "${REPOS[@]}"; do
		PATHNAME=.gitparallel/"$REPO" 
		if $MIGRATE; then
			cp -r "$GIT_ROOT"/.git/ "$PATHNAME" &&
			info "Migrated '%s/.git' to '%s/%s'." "$GIT_ROOT" "$PWD" "$PATHNAME"
		else
			mkdir "$PATHNAME" &&
			info "Created an empty Git-parallel repository '%s' in '%s'." \
				"$REPO" "$PWD"
		fi
	done
}

SYNOPSES+=(remove rm)
SYNOPSIS_remove=('gp {rm | remove} [-f | --force] REPO...')
USAGE_remove=(
'removes the specified Git-parallel REPOsitories. Removing the currently active
Git repository requires the -f / --force option.')
SYNOPSIS_rm=("${SYNOPSIS_remove[@]}")
USAGE_rm=("${USAGE_remove[@]}")

remove() {
	REPOS=()
	FORCE=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-f)											;& # fall-through
			--force)	FORCE=true		;;
			--)											;; # ignore
			*)				REPOS+=("$1")	;;
		esac
		shift
	done
	
	# Guard against bad input.
	jumpToRoot .gitparallel || return 1
	if [[ "${#REPOS[@]}" = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		return 2
	fi
	! checkNames "${REPOS[@]}" && return 3
	for REPO in "${REPOS[@]}"; do
		if [[ ! -d .gitparallel/"$REPO" ]]; then
			error "The Git-parallel repository '%s' does not exist in '%s'." \
				"$REPO" "$PWD"
			return 4
		fi
	done

	# Guard against dubious input.
	ACTIVE="`activeRepository`"
	for REPO in "${REPOS[@]}"; do
		if [[ "$REPO" = "$ACTIVE" ]] && ! $FORCE; then
			errcat <<EOF
The Git-parallel repository

	$REPO

is active. By removing it, the contents of your active Git repository WILL BE
LOST! To approve the removal, specify the -f / --force option.
EOF
			return 5
		fi
	done

	# Perform the main routine.
	for REPO in "${REPOS[@]}"; do
		rm -rf .gitparallel/"$REPO" &&
		if [[ "$REPO" = "$ACTIVE" ]]; then
			rm .git
			info "Removed the active Git-parallel repository '%s' from '%s'." \
				"$REPO" "$PWD"
		else
			info "Removed the Git-parallel repository '%s' from '%s'." "$REPO" "$PWD"
		fi
	done
}

SYNOPSES+=(checkout co)
SYNOPSIS_checkout=(
'gp {co | checkout} [-c | --create] [-m | --migrate] [-C | --clobber] REPO')
USAGE_checkout=(
"switches to the specified Git-parallel REPOsitory. When the -c / --create option
is specified, an equivalent of the 'gp init' command is performed beforehand.
If there exists a '.git' directory that is not a Git-parallel symlink to and
that would therefore be overriden by the switch, the -C / --clobber or the -m /
migrate option is required.")
SYNOPSIS_co=("${SYNOPSIS_checkout[@]}")
USAGE_co=("${USAGE_checkout[@]}")

checkout() {
	REPO=
	CREATE=false
	MIGRATE=false
	CLOBBER=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-m)												;& # fall-through
			--migrate)	MIGRATE=true	;;
			-c)												;& # fall-through
			--create)		CREATE=true		;;
			-C)												;& # fall-through
			--clobber)	CLOBBER=true	;;
			--)												;; # ignore
			 *)					if [[ -z "$REPO" ]]; then
										REPO="$1"
									else
										error 'More than one Git-parallel repository was specified.'
										return 1
									fi						;;
		esac
		shift
	done

	# Guard against bad input.
	jumpToRoot .gitparallel || return 2
	[[ -z "$REPO" ]] && error 'No Git-parallel repository was specified.' && return 3
	! checkNames "$REPO" && return 4
	if [[ ! -d .gitparallel/"$REPO" ]] && ! $CREATE; then
		error "The Git-parallel repository '%s' does not exist in '%s'." \
			"$REPO" "$PWD"
		return 5
	fi

	# Guard against dubious input.
	if { [[ -d .git ]] && ! activeRepository >/dev/null; } &&
	! { $CLOBBER || { $CREATE && $MIGRATE; }; }; then
		errcat <<-'EOF'
There exists an active Git repository that is not a symlink to a Git-parallel
repository. By switching to another Git-parallel repository, the contents of
your active Git repository WILL BE LOST! To approve the removal, specify the -C
/ --clobber option.
		EOF
		return 6
	fi

	# Perform the main routine.
	export OLDPWD && # Jump back to the original PWD for the `gp create` call.
	{ ! $CREATE || (cd "$OLDPWD" && create `$MIGRATE &&
		echo --migrate`	-- "$REPO"); } &&
	rm -rf .git && ln -s .gitparallel/"$REPO" .git &&

	# Print additional information.
	if $CREATE; then
		info "Switched to a new Git-parallel repository '%s'." "$REPO"
	else
		info "Switched to the Git-parallel repository '%s'." "$REPO"
	fi
}

SYNOPSES+=(do)
SYNOPSIS_do=(
'gp do [-f | --force] REPO... -- COMMAND'
'... | gp do [-f | --force] COMMAND')
USAGE_do=(
"switches to every specified Git-parallel REPOsitory and executes 'git
COMMAND'. When 'git COMMAND' exits with a non-zero exit code, the command is
interrupted prematurely, unless the -f / --force option is specified. After the
command has ended, the original Git repository is restored."
"switches to every Git-parallel repository that is received as a part of a
newline-separated list on the standard input and executes 'git COMMAND'. When
'git COMMAND' exits with a non-zero exit code, the command is interrupted
prematurely, unless the -f / --force option is specified. After the command has
ended, the original Git repository is restored.")

do_cmd() {
	REPOS=()
	COMMAND=()
	FORCE=false

	# Collect the options.
	ACCUMULATOR=()
	STDIN_INPUT=true
	while [[ $# > 0 ]]; do
		case "$1" in
			-f)														;& # fall-through
			--force)	FORCE=true					;;
			--)				STDIN_INPUT=false
								shift; break				;;
			 *)				ACCUMULATOR+=("$1")	;;
		esac
		shift
	done

	# Handle the overloading.
	if $STDIN_INPUT; then
		COMMAND=("${ACCUMULATOR[@]}")

		# Collect the repositories.
		while read REPO; do
			REPOS+=("$REPO")
		done
	else
		REPOS=("${ACCUMULATOR[@]}")

		# Collect the command.
		while [[ $# > 0 ]]; do
			COMMAND+=("$1")
			shift
		done
	fi

	# Guard against bad input.
	jumpToRoot .gitparallel || return 1
	if [[ "${#REPOS[@]}" = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		return 2
	fi
	! checkNames "${REPOS[@]}" && return 3
	for REPO in "${REPOS[@]}"; do
		if [[ ! -d .gitparallel/"$REPO" ]]; then
			error "The Git-parallel repository '%s' does not exist in '%s'." \
				"$REPO" "$PWD"
			return 4
		fi
	done
	if [[ -e .gitparallel/.lock ]]; then
		errcat <<-EOF
There appears to be another 'gp do' command underway. If you are certain this
is not the case, then remove the file '.lock' from '$PWD/.gitparallel'.
		EOF
		return 5
	fi

	# Perform the main routine.
	LOOP_BROKEN=false
	## Lock and remember the state of the repository.
	touch .gitparallel/.lock && {
	remember 1>&2 && {
	for REPO in "${REPOS[@]}"; do
		! checkout -- "$REPO" 1>&2 && ! $FORCE && break
		if git "${COMMAND[@]}"; then :; else
			COMMAND_STRING="${COMMAND[@]}"
			error "The command 'git %s' failed with an exit code of $?." \
				"$COMMAND_STRING"
			! $FORCE && LOOP_BROKEN=true && break
		fi
	done
	## Restore and unlock the repository.
	restore 1>&2; } }
	rm .gitparallel/.lock
	! $LOOP_BROKEN || return 6
}

# == The main routine ==

# Collect the options.
SUBCOMMAND=
case "$1" in
	ls)															;& # fall-through
	list)				SUBCOMMAND=list			;;
	i)															;& # fall-through
	init)				SUBCOMMAND=init			;;
	cr)															;& # fall-through
	create)			SUBCOMMAND=create		;;
	rm)															;& # fall-through
	remove)			SUBCOMMAND=remove		;;
	co)															;& # fall-through
	checkout)		SUBCOMMAND=checkout	;;
	do)					SUBCOMMAND=do_cmd		;;
	help)				SUBCOMMAND=help			;;
	-v)															;& # fall-through
	--version)	version; exit 0			;;
	-h)															;& # fall-through
	--help)			usage; exit 0				;;
	*)					usage; exit 1				;;
esac

# Execute the subcommand.
$SUBCOMMAND "${@:2}"
