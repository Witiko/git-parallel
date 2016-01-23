#!/bin/bash
# == The initial setup ==
export IFS=

# == Helper functions ==
info() { printf "$1\n" "${@:2}"; }
error() { info "${@}" 1>&2; }
errcat() { cat 1>&2; }

# Print the usage information.
declare -A USAGE
declare -A SYNOPSIS
usage() {
	cat <<-'EOF'
Usage:

	EOF
	for EXAMPLE in "${SYNOPSIS[@]}"; do
		printf '\t%s\n' "$EXAMPLE"
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
	echo 'Git-parallel version 1.0.1'
}

# Print help for a specific subcommand.
help() {
	# Guard against empty input.
	[[ $# = 0 ]] && usage && return 0

	# Guard against bad input.
	if [[ ! -v USAGE[$1] && ! -v SYNOPSIS[$1] ]]; then
		error "There is no command '%s'." "$1"
		return 1
	fi

	# Perform the main routine.
	printf "\n\t%s\n\n%s\n" "${SYNOPSIS[$1]}" "${USAGE[$1]}"
}

# Check if the repository names are admissible.
checkNames() {
	for NAME; do
		if [[ -z "$NAME" ]]; then
			error 'The Git-parallel repository names must be non-empty.'
			exit 1
		fi
		if grep -q '[./]' <<<"$NAME"; then
			error "The name '%s' contains illegal characters (., /)." "$NAME"
			exit 2
		fi
	done
}

# Retrieve the currently active repository.
activeRepository() {
	LINK="`readlink .git`" &&
	grep -q '^\.gitparallel/'	<<<"$LINK" &&
    sed   's#^\.gitparallel/##'	<<<"$LINK"
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
		# Print additional information.
		info "Restored the original Git repository."
	else
		# Print additional information.
		info "Removed the '.git' symlink."
	fi
}

# == Subcommands ==

SYNOPSIS[list]='gp {ls | list} [-p | --porcelain] [-H | --human-readable]'
USAGE[list]=\
"lists the available Git-parallel repositories. When the -p / --porcelain
option is specified or when the output of the command gets piped outside the
terminal, a raw newline-terminated list is produced, ready to be used by the
'gp do' command.  When the -H / --human-readable option is specified or when
the output of the command stays in the terminal, a formatted list is produced."
SYNOPSIS[ls]="${SYNOPSIS[list]}"
USAGE[ls]="${USAGE[list]}"

if [[ -t 1 ]]; then PIPED=false; else PIPED=true; fi
list() {
	PORCELAIN=$PIPED

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-p)									;&
			--porcelain)		PORCELAIN=true	;;
			-H)									;&
			--human-readable)	PORCELAIN=false	;;
			*)					error "An unexpected argument '%s'." "$1"
								exit 1			;;
		esac
		shift
	done

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

SYNOPSIS[create]='gp {cr | create} [-m | --migrate] [--] REPO...'
USAGE[create]=\
'creates new Git-parallel REPOsitories. When the -m / --migrate option is
specified, the REPOSITORies are initialized with the contents of the currently
active Git repository.'
SYNOPSIS[cr]="${SYNOPSIS[create]}"
USAGE[cr]="${USAGE[create]}"

create() {
	REPOS=()
	MIGRATE=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-m)							;&
			--migrate)	MIGRATE=true	;;
			--)			shift; break    ;;
			*)			REPOS+=("$1")	;;
		esac
		shift
	done
	
	# Collect the repositories.
	while [[ $# > 0 ]]; do
		REPOS+=("$1")
		shift
	done
	
	# Guard against bad input.
	if [[ "${#REPOS[@]}" = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		exit 1
	fi
	! checkNames "${REPOS[@]}" && exit 2
	for REPO in "${REPOS[@]}"; do
		if [[ -d .gitparallel/"$REPO" ]]; then
			error "The Git-parallel repository '%s' already exists." "$REPO"
			exit 3
		fi
	done
	if $MIGRATE && [[ ! -d .git || -L .git ]]; then
		error 'There exists no Git repository to migrate.'
		exit 4
	fi

	# Perform the main routine.
	if [[ ! -d .gitparallel ]]; then
		mkdir .gitparallel
	fi &&
	for REPO in "${REPOS[@]}"; do
		PATHNAME=.gitparallel/"$REPO" 
		if $MIGRATE; then
			cp -r .git/ "$PATHNAME" &&
			# Print additional information.
			info "Migrated the active Git repository to '$PATHNAME'."
		else
			mkdir "$PATHNAME" &&
			# Print additional information.
			info "Initialized an empty Git-parallel repository in '$PATHNAME'."
		fi
	done
}

SYNOPSIS[remove]='gp {rm | remove} [-f | --force] [--] REPO...'
USAGE[remove]=\
'removes the specified Git-parallel REPOsitories. Removing the currently active
Git repository requires the -f / --force option.'
SYNOPSIS[rm]="${SYNOPSIS[remove]}"
USAGE[rm]="${USAGE[remove]}"

remove() {
	REPOS=()
	FORCE=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-f)								;&
			--force)	FORCE=true			;;
			--)			shift; break	    ;;
			*)			REPOS+=("$1")	;;
		esac
		shift
	done
	
	# Collect the repositories.
	while [[ $# > 0 ]]; do
		REPOS+=("$1")
		shift
	done
	
	# Guard against bad input.
	if [[ "${#REPOS[@]}" = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		exit 1
	fi
	! checkNames "${REPOS[@]}" && exit 2
	for REPO in "${REPOS[@]}"; do
		if [[ ! -d .gitparallel/"$REPO" ]]; then
			error "The Git-parallel repository '%s' does not exist." "$REPO"
			exit 3
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
			exit 4
		fi
	done

	# Perform the main routine.
	for REPO in "${REPOS[@]}"; do
		rm -rf .gitparallel/"$REPO" &&
		if [[ "$REPO" = "$ACTIVE" ]]; then
			rm .git
			# Print additional information.
			info "Removed the active Git-parallel repository '%s'." "$REPO"
		else
			# Print additional information.
			info "Removed the Git-parallel repository '%s'." "$REPO"
		fi
	done
}

SYNOPSIS[checkout]=\
'gp {co | checkout} [-c | --create] [-m | --migrate] [-C | --clobber] [--] REPO'
USAGE[checkout]=\
"switches to the specified Git-parallel REPOsitory. When the -i / --init option
is specified, an equivalent of the 'gp init' command is performed beforehand.
If there exists a '.git' directory that is not a Git-parallel symlink to and
that would therefore be overriden by the switch, the -C / --clobber or the -m /
migrate option is required."
SYNOPSIS[co]="${SYNOPSIS[checkout]}"
USAGE[co]="${USAGE[checkout]}"

checkout() {
	REPO=
	CREATE=false
	MIGRATE=false
	CLOBBER=false

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-m)								;&
			--migrate)	MIGRATE=true		;;
			-c)								;&
			--create)	CREATE=true			;;
			-C)								;&
			--clobber)	CLOBBER=true		;;
			--)			shift; break	    ;;
			 *)	if [[ -z "$REPO" ]]; then
					REPO="$1"
				else
					error 'More than one Git-parallel repository was specified.'
					exit 1
				fi							;;
		esac
		shift
	done

	# Collect the repository.
	if [[ $# > 1 ]]; then
		error 'More than one Git-parallel repository was specified.'
		exit 1
	fi
	if [[ $# = 1 ]]; then
		if [[ -z "$REPO" ]]; then
			REPO="$1"
		else
			error 'More than one Git-parallel repository was specified.'
			exit 1
		fi
	fi

	# Guard against bad input.
	[[ -z "$REPO" ]] && error 'No Git-parallel repository was specified.' && exit 2
	! checkNames "$REPO" && exit 3
	if [[ ! -d .gitparallel/"$REPO" ]] && ! $CREATE; then
		error "The Git-parallel repository '%s' does not exist." "$REPO"
		exit 4
	fi

	# Guard against dubious input.
	if { [[ -d .git ]] && ! activeRepository >/dev/null; } &&
	! { $CLOBBER || $MIGRATE; }; then
		errcat <<-'EOF'
There exists an active Git repository that is not a symlink to a Git-parallel
repository. By switching to another Git-parallel repository, the contents of
your active Git repository WILL BE LOST! To approve the removal, specify the -C
/ --clobber option.
		EOF
		exit 5
	fi

	# Perform the main routine.
	{ ! $CREATE || create `$MIGRATE && echo --migrate` -- "$REPO"; } &&
	rm -rf .git && ln -s .gitparallel/"$REPO" .git &&

	# Print additional information.
	if $CREATE; then
		info "Switched to a new Git-parallel repository '%s'." "$REPO"
	else
		info "Switched to the Git-parallel repository '%s'." "$REPO"
	fi
}

SYNOPSIS[do]='... | gp do [-f | --force] [--] COMMAND'
USAGE[do]=\
"switches to every Git-parallel repository that is received as a part of a
newline-separated list on the standard input and executes 'git COMMAND'. When
'git COMMAND' exits with a non-zero exit code, the loop is interrupted
prematurely, unless the -f / --force option is specified. After the loop has
ended, the original Git repository is restored."

do_cmd() {
	REPOS=()
	COMMAND=()
	FORCE=false

	# Collect the repositories.
	while read REPO; do
		REPOS+=("$REPO")
	done

	# Collect the options.
	while [[ $# > 0 ]]; do
		case "$1" in
			-f)							;&
			--force)	FORCE=true		;;
			--)			shift; break	;;
			 *)			COMMAND+=("$1")	;;
		esac
		shift
	done

	# Collect the command.
	while [[ $# > 0 ]]; do
		COMMAND+=("$1")
		shift
	done

	# Guard against bad input.
	if [[ "${#REPOS[@]}" = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		exit 1
	fi
	! checkNames "${REPOS[@]}" && exit 2
	for REPO in "${REPOS[@]}"; do
		if [[ ! -d .gitparallel/"$REPO" ]]; then
			error "The Git-parallel repository '%s' does not exist." "$REPO"
			exit 3
		fi
	done

	# Perform the main routine.
	remember 1>&2 && {
	for REPO in "${REPOS[@]}"; do
		if { ! checkout -- "$REPO" 1>&2 || ! git "${COMMAND[@]}"; } &&
		! $FORCE; then
			error "The do command ended prematurely at the Git-parallel repository '%s'." "$REPO"
			restore 1>&2
			exit 4
		fi
	done
	restore 1>&2; }
}

# == The main routine ==

# Collect the options.
SUBCOMMAND=
case "$1" in
	ls)								;&
	list)		SUBCOMMAND=list		;;
	cr)								;&
	create)		SUBCOMMAND=create	;;
	rm)								;&
	remove)		SUBCOMMAND=remove	;;
	co)								;&
	checkout)	SUBCOMMAND=checkout	;;
	do)			SUBCOMMAND=do_cmd	;;
	help)		SUBCOMMAND=help		;;
	-v)								;&
	--version)	version; exit 0		;;
	-h)								;&
	--help)		usage; exit 0		;;
	*)			usage; exit 1		;;
esac

# Execute the subcommand.
$SUBCOMMAND "${@:2}"
