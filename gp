#!/bin/bash
################################################################################
#
# Git-parallel - A tool for maintaining several Git repos in a single directory
# Copyright (C) 2016 Vít Novotný
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

# == The initial setup ==
OLDIFS="$IFS"
export IFS=

# == Helper functions ==

# Wrap the input to fit neatly to the terminal.
wrap() {
 	if [[ -t 1 ]] && hash fmt 2>&-; then
		fmt -u -w $(if hash tput 2>&- && [[ "`tput cols`" -lt 80 ]]; then
			echo `tput cols`
		else
			echo 80
		fi) | if [[ $1 =~ --paragraph ]]; then
			sed '2,$s/^/  /'
		else
			cat
		fi
	else
		cat
	fi
}

# Emit info or warning messages.
VERBOSE=true
error() { printf -- "$1\n" "${@:2}" | wrap 1>&2; }
errcat() { wrap 1>&2; }
info() { ! $VERBOSE || error "${@}"; }
infocat() { ! $VERBOSE || errcat; }

# The main routine.
[[ -v GP_EXECUTABLE ]] || GP_EXECUTABLE="${0##*/}"
GLOBAL_OPTIONS='[-q | --quiet]'
GLOBAL_USAGE=\
"The -q / --quiet option makes '$GP_EXECUTABLE' omit extra informational
output regarding its operation."

main() {
	# Collect the options.
	if [[ -v NAME_TO_FUNCTION["$1"] ]]; then
		SUBCOMMAND="${NAME_TO_FUNCTION["$1"]}"
	else
		case "$1" in
			-q)																;& # fall-through
			--quiet)		VERBOSE=false
									main "${@:2}"
									return $?							;;
			-v)																;& # fall-through
			--version)	version; return 0			;;
			-h)																;& # fall-through
			--help)			usage; return 0				;;
			*)					usage; return 1				;;
		esac
	fi

	# Execute the subcommand.
	lock $SUBCOMMAND && $SUBCOMMAND "${@:2}"
}

# Register a new subcommand.
declare -A NAME_TO_FUNCTION LOCKS SYNOPSES USAGES
declare -a SUBCOMMANDS
newSubcommand() {
	local FUNCTION LOCK=none SYNOPSIS USAGE NAMES=() HIDDEN=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		local KEY="${1%%=*}"
		local VALUE="${1#*=}"
		if [[ -z "$VALUE" ]]; then
			error "%s: Empty value specified for '%s'." "$VALUE"
			return 1
		fi
		case "$KEY" in
			FUNCTION)	FUNCTION=$VALUE										;;
			LOCK)			LOCK=$VALUE												;;
			SYNOPSIS)	SYNOPSIS="$VALUE"									;;
			USAGE)		USAGE="$VALUE"										;;
			HIDDEN)		HIDDEN=true												;;
			NAMES)																			;& # fall-through
			NAME)			IFS=, read -ra NAMES <<<"$VALUE"	;;
			*)				error "An unexpected argument '%s'." "$1"
								return 2													;;
		esac
		shift
	done

	# Guard against bad input.
	if [[ -z "$FUNCTION" ]]; then
		error '%s: No function name specified.' $FUNCTION
		return 3
	fi
	if [[ ! "$LOCK" =~ none|shared|exclusive ]]; then
		error "%s: An unknown lock type '%s' specified." $FUNCTION "$LOCK"
	fi
	if ! $HIDDEN; then
		if [[ -z "$USAGE" ]]; then
			error '%s: No usage specified.' $FUNCTION
			return 5
		fi
	fi
	if [[ ${#NAMES[@]} = 0 ]]; then
		error '%s: No names specified.' $FUNCTION
		return 6
	fi
	for NAME in "${NAMES[@]}"; do
		if [[ -v NAME_TO_FUNCTION["$NAME"] ]]; then
			error "%s: Subcommand name '%s' already registered." $FUNCTION "$NAME"
			return 7
		fi
	done
	if [[ " ${SUBCOMMANDS[@]} " =~ " $FUNCTION " ]]; then
		error "%s: Function has already been registered." $FUNCTION
		return 8
	fi

	# Perform the main routine.
	for NAME in "${NAMES[@]}"; do
		NAME_TO_FUNCTION["$NAME"]=$FUNCTION
	done
	LOCKS[$FUNCTION]=$LOCK
	SYNOPSES[$FUNCTION]="$(
		if [[ ${#NAMES[@]} = 1 ]]; then
			printf '%s\n' "${NAMES[0]}"
		else
			local IFS='|'
			printf '{%s}\n' "${NAMES[*]}" | sed 's/|/ | /g'
		fi
	)$([[ $SYNOPSIS != none ]] && printf ' %s\n' "$SYNOPSIS")"
	if [[ ! -z "$USAGE" ]]; then
		USAGES[$FUNCTION]="$USAGE"
	fi
	$HIDDEN || SUBCOMMANDS+=($FUNCTION)
}

# Print the usage information.
usage() {
	wrap <<-EOF
Usage:

  $GP_EXECUTABLE $GLOBAL_OPTIONS COMMAND

$GLOBAL_USAGE '$GP_EXECUTABLE' recognizes the following COMMANDs:

	EOF
	for SUBCOMMAND in "${SUBCOMMANDS[@]}"; do
		printf '  %s\n' "${SYNOPSES[$SUBCOMMAND]}" | wrap --paragraph
	done
	wrap <<EOF

To see more information about any individual COMMAND, execute

  $GP_EXECUTABLE help COMMAND

EOF
	if { ! hash flock || ! hash fmt; } 2>&-; then
		wrap <<<'The following suggested binaries are unavailable at your system:'
		hash flock 2>&- && wrap <<'EOF'

  'flock' is used to perform advisory locking, when Git-parallel commands are
executed. This can prevent race conditions on multi-user systems.
EOF
		hash fmt 2>&- && wrap <<'EOF'

  'fmt' is used to wrap the text output of Git-parallel, so that it fits your
terminal neatly.
EOF
	echo
	fi
	wrap<<< 'Report bugs to: <witiko@mail.muni.cz>'
	wrap<<< 'Git-parallel home page: <http://github.com/witiko/Git-parallel>'
}

# Print the version information.
VERSION=2.1.1
version() {
	wrap <<<"Git-parallel version $VERSION"
	wrap <<<"Copyright © 2016 Vít Novotný"
	wrap <<-'EOF'
		License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
		This is free software: you are free to change and redistribute it.
		There is NO WARRANTY, to the extent permitted by law.
	EOF
}

# Check if the repository name is admissible.
checkName() {
	if [[ -z "$1" ]]; then
		error 'Git-parallel repository names must be non-empty.'
		return 1
	fi
	if [[ "$1" =~ ^\. ]]; then
		error 'Git-parallel repository names may not start with a dot.'
		return 2
	fi
	if [[ "$1" =~ ^- ]]; then
		error 'Git-parallel repository names may not start with a hyphen.'
		return 3
	fi
	if [[ "$(printf '%s' "$1" | wc -l)" -gt 0 ]] || grep -q '\s' <<<"$1"; then
		errcat <<-'EOF'
			Git-parallel repository names may not contain spaces, tabs or newlines.
		EOF
		return 4
	fi
	if [[ "$1" =~ / ]]; then
		error 'Git-parallel repository names may not contain a slash.'
		return 5
	fi
}

# Acquire the advisory lock for the subcommand $1.
GP_DIR=.gitparallel
GP_DIR_RE=`eval echo \\$GP_DIR`
lock() {
	local SUBCOMMAND=$1
	if hash flock 2>&-; then
		LOCKTYPE=${LOCKS[$SUBCOMMAND]}
		if [[ $LOCKTYPE != none ]] && ROOT=`findRoot $GP_DIR 2>/dev/null`; then
			LOCKDESCRIPTOR=3
			LOCKPATH=$ROOT/$GP_DIR/.lock
			eval exec $LOCKDESCRIPTOR\>$LOCKPATH
			if ! flock --nonblock --$LOCKTYPE $LOCKDESCRIPTOR; then
				# Be verbose, if the lock is currently held.
				info "Acquiring an advisory %s lock on '%s' ..." $LOCKTYPE $LOCKPATH
				if flock --$LOCKTYPE $LOCKDESCRIPTOR; then
					info 'Successfully acquired the lock.'
				else
					error 'Failed to acquire the lock.'
					return 1
				fi
			fi
		fi
	fi
}

# Determine, if a Git-parallel repository is compatible with the current
# version of the program, or if it has to be `gp upgrade`d.
VERSIONFILE=$GP_DIR/.version
isCompatible() {
	if [[ -e $VERSIONFILE ]]; then
		# The repository is compatible, if 2.0.0 <= version < 3.0.0.
		if [[ "`cat $VERSIONFILE`" =~ ^2\. ]]; then
			return 0
		else
			errcat <<-EOF
The version of the Git-parallel repository in directory '$PWD' (<2.0.0) is
incompatible with the current version of the program ($VERSION). In order to
work with the repository, update the program.
			EOF
			return 1
		fi
	else
		errcat <<-EOF
The version of the Git-parallel repository in directory '$PWD' (<2.0.0) is
incompatible with the current version of the program ($VERSION). Run
'$GP_EXECUTABLE upgrade' to bring the repository up to date.
		EOF
		return 2
	fi
}

# Retrieve the nearest directory containing the directory $1. If $1 is
# `$GP_DIR`, check whether the retrieved directory is compatible with the
# current version of the program.
findRoot() {
	local PTH=.
	(while [[ $PWD != / && ! -d "$1" ]]; do
		PTH=$PTH/..
		cd ..
	done
	if [[ -d "$1" ]]; then
		if [[ "$1" != $GP_DIR || "$2" = --ignore-compatibility ]] ||
		isCompatible "$PTH"; then
			printf '%s\n' $PTH
		else
			return 1
		fi
	else
		return 2
	fi)
}

# Retrieve the nearest directory containing the directory $1 and change the
# working directory to it.
jumpToRoot() {
	local ROOT RETVAL
	ROOT=`findRoot "$1" "$2"`
	RETVAL=$?
	case "$RETVAL" in
		0)	cd $ROOT	;;
		1)	return 1	;;
		2)	error "No directory '%s' was found in '%s' or its parents." "$1" "$PWD"
				return 2	;;
	esac
}

# Stash the current state of the working directory.
STASH=$GP_DIR/.stash
stash() {
	# Guard against bad input.
	if [[ -e $STASH ]]; then
		if [[ -f $STASH ]]; then
			errcat <<-EOF
The Git-parallel repository '`cat $STASH`' has already been stashed.
			EOF
			return 1
		else
			errcat <<-EOF
There already exists a Git repository stashed at '$PWD/$STASH'.
			EOF
			return 2
		fi
	fi

	# Perform the main routine.
	local ACTIVE
	if ACTIVE=`list --active`; then
		rm $GP_DIR/$ACTIVE &&
		mv -T .git $GP_DIR/$ACTIVE &&
		printf '%s\n' $ACTIVE >$STASH &&
		infocat <<-EOF
The active Git-parallel repository '$ACTIVE' has been stashed.
		EOF
	else
		if [[ -e .git ]]; then
			mv -T .git $STASH &&
			infocat <<-EOF
The Git repository '$PWD/.git' has been stashed at '$PWD/$STASH'.
			EOF
		fi
	fi || return 3
}

# Restore the previous state of the working directory from the stash.
restore() {
	local ACTIVE
	if ACTIVE=`list --active`; then
		rm $GP_DIR/$ACTIVE &&
		mv -T .git $GP_DIR/$ACTIVE
	else
		rm -rf .git
	fi || return 1
	if [[ -e $STASH ]]; then
		if [[ -f $STASH ]]; then
			read ACTIVE <$STASH &&
			checkName "$ACTIVE" &&
			checkout $ACTIVE &&
			rm $STASH &&
			infocat <<-EOF
Recovered the Git-parallel repository '$ACTIVE' from the stash.
			EOF
		else
			mv -T $STASH .git &&
			infocat <<-EOF
Recovered the Git repository '$PWD/.git' from the stash.
			EOF
		fi
	fi || return 2
}

# == Subcommands ==

newSubcommand   \
	FUNCTION=help \
	NAMES=help    \
	LOCK=none     \
	HIDDEN

help() {
	# Guard against empty input.
	[[ $# = 0 ]] && usage && return 0

	# Guard against bad input.
	if [[ ! -v NAME_TO_FUNCTION["$1"] ]]; then
		error "There is no subcommand '%s'." "$1"
		return 1
	fi
	local SUBCOMMAND="${NAME_TO_FUNCTION["$1"]}"
	if [[ ! -v USAGES["$SUBCOMMAND"] ]]; then
		error "There is no usage information available for subcommand '%s'." "$1"
		return 2
	fi

	# Perform the main routine.
	wrap <<<$'\n'"  ${SYNOPSES[$SUBCOMMAND]}"$'\n'
	wrap <<<"${USAGES[$SUBCOMMAND]}"$'\n'
}

newSubcommand      \
	FUNCTION=upgrade \
	NAMES=upgrade    \
	LOCK=exclusive   \
	SYNOPSIS=none    \
	USAGE=\
"upgrades a '$GP_DIR' directory created with an earlier version of
Git-parallel, so that it can be used with the current version of Git-parallel.
You are advised to back up your '$GP_DIR' directory before executing this
command." \
	HIDDEN

upgrade() {
	# Check for bad input.
	if isCompatible 2>/dev/null; then
		infocat <<-EOF
The Git-parallel directory '$PWD/$GP_DIR' is already up to date.
		EOF
		return 0
	else
		if [[ $? = 1 ]]; then
			infocat <<-EOF
The Git-parallel directory '$PWD/$GP_DIR' was created with a newer version of
Git-parallel. To work with the directory, update the program.
			EOF
			return 1
		fi
	fi

	# Perform the main routine.
	jumpToRoot $GP_DIR --ignore-compatibility || return 2

	# For versions <2.0.0, swap symlinks and directories.
	upgrade_sub_2.0.0 || return 3

	# Upgrade the version file.
	printf '%s\n' "$VERSION" >"$VERSIONFILE" &&
	infocat <<-EOF
Upgraded the Git-parallel repository in directory '$PWD' to version
'$VERSION'.
	EOF
}

upgrade_sub_2.0.0() {
	# Check for bad input.
	if ! hash readlink 2>&-; then
		errorcat <<-'EOF'
The 'readlink' program is required to upgrade the Git-parallel repository.
		EOF
		return 3
	fi
	if [[ -L .git && -e .git ]]; then
		local LINK
		if ! LINK="`readlink .git`" || [[ ! $LINK =~ ^$GP_DIR_RE/.* ]]; then
			errcat <<-EOF
Unable to swap the polarity of the symlink '.git -> $LINK' in '$PWD', since it
points outside the '$GP_DIR' directory.
			EOF
			return 3
		fi
	fi

	# Perform the main routine.
	## Initialize empty Git-parallel repositories.
	(shopt -s nullglob && cd $GP_DIR &&
	for REPO in */; do
		REPO="${REPO%/}"
		if checkName "$REPO" 2>/dev/null && [[ `ls $REPO | wc -l` = 0 ]]; then
			rmdir $REPO &&
			git init &&
			mv -T .git $REPO &&
			infocat <<-EOF
Initialized the empty Git-parallel repository '$REPO' in '$OLDPWD'.
			EOF
		fi
	done) || return 2

	## Swap the polarity of the active repository symlink.
	if [[ -L .git && -e .git ]]; then
		LINK="`readlink .git`" &&
		rm .git &&
		mv -T "$LINK" .git &&
		(cd "${LINK%/*}" &&
		ln -s ../.git "${LINK##*/}" &&
		info "Turned the symlink '.git -> %s' in '$OLDPWD' into '.git <- %s'." \
			"$LINK" "$LINK") || return 4
	fi
}

newSubcommand   \
	FUNCTION=init \
	NAMES=i,init  \
	LOCK=none     \
	SYNOPSIS=\
'[-F | --follow-git] [-u | --update-gitignore]' \
	USAGE=\
"creates a new '$GP_DIR' directory in the current working directory. This
directory is going to serve as a container for any Git-parallel repositories
created afterwards.  The remaining '$GP_EXECUTABLE' commands will operate with
the '$GP_DIR' directory in the nearest parent directory containing one. If none
exists, the commands will issue an error.

When the -F / --follow-git option is specified, the '$GP_DIR' directory will be
created next to the current Git repository root rather than inside the current
working directory. When the -u / --update-gitignore option is specified, an
entry for the '$GP_DIR' directory will be added to the '.gitignore' file."

init() {
	local FOLLOW_GIT=false
	local UPDATE_GITIGNORE=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
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
	if [[ -d $GP_DIR ]]; then
		error "There already exists a '$GP_DIR' directory in '%s'." "$PWD"
		return 2
	fi

	# Perform the main routine.
	mkdir $GP_DIR && trap 'rm -rf $GP_DIR' EXIT &&
	printf '%s\n' "$VERSION" >$GP_DIR/.version &&
	trap - EXIT &&
	info "Created a '$GP_DIR' directory in '%s'." "$PWD" &&
	if $UPDATE_GITIGNORE; then
		if [[ ! -e .gitignore ]]; then
			printf '%s\n' $GP_DIR >.gitignore
			info "Created a '.gitignore' file."
		else
			if [[ -e .gitignore ]] && ! grep -q ^$GP_DIR_RE <.gitignore; then
				printf '%s\n' $GP_DIR >>.gitignore
				info "Updated the '.gitignore' file."
			else
				info "No update of the '.gitignore' file was necessary."
			fi
		fi
	fi
}

newSubcommand   \
	FUNCTION=list \
	NAMES=ls,list \
	LOCK=shared   \
	SYNOPSIS=\
'[{-p | --porcelain} | {-H | --human-readable} | {-a | --active}]' \
	USAGE=\
"lists the available Git-parallel repositories. When the -p / --porcelain
option is specified or when the output of the command gets piped outside the
terminal, a raw newline-terminated list is produced. When the -H /
--human-readable option is specified or when the output of the command stays in
the terminal, a formatted list is produced. When the -a / --active option is
specified, only the active directory is listed."

list() {
	local PORCELAIN
	if [[ -t 1 ]]; then
		PORCELAIN=false
	else
		PORCELAIN=true
	fi
	local ONLY_ACTIVE=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-p)																	;& # fall-through
			--porcelain)			PORCELAIN=true		;;
			-H)																	;& # fall-through
			--human-readable)	PORCELAIN=false		;;
			-a)																	;& # fall-through
			--active)					ONLY_ACTIVE=true	;;
			--)																	;; # ignore
			*)								error "An unexpected argument '%s'." "$1"
												return 1					;;
		esac
		shift
	done

	# Guard against bad input.
	jumpToRoot $GP_DIR || return 1

	# Perform the main routine.
	(shopt -s nullglob && for REPO in $GP_DIR/*/; do
		REPO="${REPO%/}"
		local NAME="${REPO#$GP_DIR/}"
		checkName "$NAME" 2>/dev/null || continue
		if [[ -L $REPO && -d $REPO ]]; then
			if $ONLY_ACTIVE; then
				printf '%s\n' $NAME
				exit 0
			else
				! $PORCELAIN && printf '* \033[32m'
				printf '%s' $NAME
				if ! $PORCELAIN; then
					printf '\033[m -> %s/.git\n' "$PWD"
				else
					printf '\n'
				fi
			fi
		else
			if ! $ONLY_ACTIVE; then
				! $PORCELAIN && printf '  '
				printf '%s\n' $NAME
			fi
		fi
	done
	if $ONLY_ACTIVE; then
		exit 1
	fi) || return 1
}

newSubcommand     \
	FUNCTION=create \
	NAMES=cr,create \
	LOCK=exclusive  \
	SYNOPSIS=\
'[-m | --migrate] REPO...' \
	USAGE=\
"creates new Git-parallel REPOsitories. When the -m / --migrate option is
specified, the REPOsitories are initialized with the contents of the currently
active Git repository. Otherwise, the REPOsitories are initialized by running
'git init'."

create() {
	local REPOS=()
	local MIGRATE=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-m)												;& # fall-through
			--migrate)	MIGRATE=true	;;
			--)												;; # ignore
			*)					checkName "$1" || return 1
									REPOS+=($1)	;;
		esac
		shift
	done
	
	# Guard against bad input.
	local GIT_ROOT
	$MIGRATE && ! GIT_ROOT="`jumpToRoot .git && printf '%s\n' "$PWD"`" && return 2
	jumpToRoot $GP_DIR || return 3
	if [[ ${#REPOS[@]} = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		return 4
	fi
	local REPO; for REPO in ${REPOS[@]}; do
		if [[ -d $GP_DIR/$REPO ]]; then
			error "The Git-parallel repository '%s' already exists." $REPO
			return 5
		fi
	done

	# Perform the main routine.
	for REPO in ${REPOS[@]}; do
		if $MIGRATE; then
			cp -Ta "$GIT_ROOT"/.git $GP_DIR/$REPO &&
			info "Migrated '%s/.git' to '%s/%s'." "$GIT_ROOT" "$PWD" $GP_DIR/$REPO
		else
			local FAILED=true
			stash &&
			(cd $GP_DIR
			git init &&
			mv -T .git $REPO) &&
			FAILED=false

			if ! restore || $FAILED; then
				return 6
			else
				info "Created an empty Git-parallel repository '%s' in '%s'." \
					$REPO "$PWD"
			fi
		fi || return 6
	done
}

newSubcommand    \
	FUNCTION=copy  \
	NAMES=cp,copy  \
	LOCK=exclusive \
	SYNOPSIS=\
'[-C | --clobber] {DEST | SOURCE DEST...}' \
	USAGE=\
'copies the Git-parallel repository SOURCE to DEST. If SOURCE is unspecified,
the currently active Git-parallel repository will be copied. Overriding
existing DEST repositories requires the -C / --clobber option.'

copy() {
	local REPOS=()
	local CLOBBER=false
	local FORCE=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-C)												;& # fall-through
			--clobber)	CLOBBER=true	;;
			-f)											;& # fall-through
			--force)	FORCE=true		;;
			--)												;; # ignore
			*)					checkName "$1" || return 1
									REPOS+=($1)	;;
		esac
		shift
	done

	# Process the options.
	local SOURCE DESTS
	jumpToRoot $GP_DIR || return 2
	if [[ ${#REPOS[@]} = 0 ]]; then
		error 'No Git-parallel repositories specified.'
		return 2
	fi
	if [[ ${#REPOS[@]} = 1 ]]; then
		if ! SOURCE=`list --active`; then
			errcat<<-'EOF'
No source Git-parallel repository was specified and could not be inferred,
since no Git-parallel repository is currently active.
			EOF
			return 3
		fi
		DESTS=(${REPOS[0]})
	else
		SOURCE=${REPOS[0]}
		local IFS=$'\n' # Remove duplicates from the array.
		DESTS=($(awk '!s[$0]++' <<<"$(printf '%s\n' "${REPOS[*]:1}")"))
		IFS=
	fi

	# Guard against bad input.
	if [[ ! -d $GP_DIR/$SOURCE ]]; then
		error "The Git-parallel repository '%s' does not exist." $SOURCE
		return 4
	fi

	local DEST; for DEST in ${DESTS[@]}; do
		# Guard against bad input.
		if [[ -d $GP_DIR/$DEST ]] && ! $CLOBBER; then
			errcat <<-EOF
A Git-parallel repository '$DEST' already exists. To override the existing
repository, specify the -C / --clobber option.
			EOF
			return 5
		fi

		# Guard against dubious input.
		if [[ $SOURCE = $DEST ]]; then
			errcat <<-EOF
You are attempting to move the Git-parallel repository $SOURCE onto itself.
			EOF
			return 6
		fi
	done

	# Perform the main routine.
	local ACTIVE=`list --active 2>/dev/null`
	for DEST in ${DESTS[@]}; do
		if [[ $DEST = $ACTIVE ]]; then
			rm $GP_DIR/$DEST &&
			info 'There is currently no active Git-parallel repository.'
		else
			rm -rf $GP_DIR/$DEST
		fi && cp -Ta $GP_DIR/$SOURCE/ $GP_DIR/$DEST || return 7
	done
}

newSubcommand          \
	FUNCTION=move        \
	NAMES=mv,move,rename \
	LOCK=exclusive       \
	SYNOPSIS=\
'[-C | --clobber] [SOURCE] DEST' \
	USAGE=\
'renames the Git-parallel repository SOURCE to DEST. If SOURCE is unspecified,
the currently active Git-parallel repository will be renamed. Overriding an
existing DEST repository requires the -C / --clobber option.'

move() {
	local REPOS=()
	local CLOBBER=false
	local FORCE=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-C)												;& # fall-through
			--clobber)	CLOBBER=true	;;
			-f)												;& # fall-through
			--force)		FORCE=true		;;
			--)												;; # ignore
			*)					checkName "$1" || return 1
									REPOS+=($1)	;;
		esac
		shift
	done

	# Process the options.
	local SOURCE DEST
	jumpToRoot $GP_DIR || return 2
	if [[ ${#REPOS[@]} = 0 || ${#REPOS[@]} -gt 2 ]]; then
		errcat <<-EOF
An incorrect number of Git-parallel repositories (${#REPOS[@]}) specified.
		EOF
		return 2
	fi
	if [[ ${#REPOS[@]} = 1 ]]; then
		if ! SOURCE=`list --active 2>/dev/null`; then
			errcat<<-'EOF'
No source Git-parallel repository was specified and could not be inferred,
since no Git-parallel repository is currently active.
			EOF
			return 3
		fi
		DEST=${REPOS[0]}
	else
		SOURCE=${REPOS[0]}
		DEST=${REPOS[1]}
	fi

	# Guard against bad input.
	if [[ ! -d $GP_DIR/$SOURCE ]]; then
		error "The Git-parallel repository '%s' does not exist." $SOURCE
		return 4
	fi
	if [[ -d $GP_DIR/$DEST ]] && ! $CLOBBER; then
		errcat <<-EOF
A Git-parallel repository '$DEST' already exists. To override the existing
repository, specify the -C / --clobber option.
		EOF
		return 5
	fi

	# Guard against dubious input.
	if [[ $SOURCE = $DEST ]]; then
		errcat <-EOF
You are attempting to move the Git-parallel repository $DEST onto itself.
		EOF
		return 5
	fi

	# Perform the main routine.
	local ACTIVE=`list --active 2>/dev/null`
	if [[ $DEST = $ACTIVE ]]; then
		rm $GP_DIR/$DEST &&
		info 'There is currently no active Git-parallel repository.'
	else
		rm -rf $GP_DIR/$DEST
	fi && mv -T $GP_DIR/$SOURCE $GP_DIR/$DEST || return 6
}

newSubcommand     \
	FUNCTION=remove \
	NAMES=rm,remove \
	LOCK=exclusive  \
	SYNOPSIS=\
'[-f | --force] REPO...' \
	USAGE=\
'removes the specified Git-parallel REPOsitories. Removing the currently active
Git repository requires the -f / --force option.'

remove() {
	local REPOS=()
	local FORCE=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-f)											;& # fall-through
			--force)	FORCE=true		;;
			--)											;; # ignore
			*)				checkName "$1" || return 1
								REPOS+=($1)		;;
		esac
		shift
	done
	
	# Guard against bad input.
	jumpToRoot $GP_DIR || return 2
	if [[ ${#REPOS[@]} = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		return 3
	fi
	local REPO; for REPO in ${REPOS[@]}; do
		if [[ ! -d $GP_DIR/$REPO ]]; then
			error "The Git-parallel repository '%s' does not exist in '%s'." \
				$REPO "$PWD"
			return 4
		fi
	done

	# Guard against dubious input.
	local ACTIVE="`list --active 2>/dev/null`"
	for REPO in ${REPOS[@]}; do
		if [[ $REPO = $ACTIVE ]] && ! $FORCE; then
			errcat <<-EOF
The Git-parallel repository	'$REPO' is active. By removing it, the contents of
your active Git repository WILL BE LOST! To approve the removal, specify the -f
/ --force option.
			EOF
			return 5
		fi
	done

	# Perform the main routine.
	for REPO in ${REPOS[@]}; do
		if [[ $REPO = $ACTIVE ]]; then
			rm $GP_DIR/$REPO &&
			rm -rf .git &&
			info "Removed the active Git-parallel repository '%s' from '%s'." \
				$REPO "$PWD"
		else
			rm -rf $GP_DIR/$REPO &&
			info "Removed the Git-parallel repository '%s' from '%s'." $REPO "$PWD"
		fi
	done
}

newSubcommand       \
	FUNCTION=checkout \
	NAMES=co,checkout \
	LOCK=exclusive    \
	SYNOPSIS=\
'[[{-c | --create} [-m | --migrate]] [-C | --clobber] REPO]' \
	USAGE=\
"switches to the specified Git-parallel REPOsitory. When the -c / --create
option is specified, an equivalent of the '$GP_EXECUTABLE create' command is
performed beforehand. If there exists a '.git' directory that is not a symlink
to '$GP_DIR' and that would therefore be overriden by the switch, the -C /
--clobber or the -m / migrate option is required.

When no Git-parallel REPOsitories are specified, the active Git-parallel
repository is deactivated (pulled back into the '$GP_DIR' directory)."

checkout() {
	local REPO=
	local CREATE=false
	local MIGRATE=false
	local CLOBBER=false

	# Collect the options.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-m)												;& # fall-through
			--migrate)	MIGRATE=true	;;
			-c)												;& # fall-through
			--create)		CREATE=true		;;
			-C)												;& # fall-through
			--clobber)	CLOBBER=true	;;
			--)												;; # ignore
			 *)					checkName "$1" || return 1
				 					if [[ -z $REPO ]]; then
										REPO=$1
									else
										error 'More than one Git-parallel repository were specified.'
										return 2
									fi						;;
		esac
		shift
	done

	# Guard against bad input.
	jumpToRoot $GP_DIR || return 3
	if [[ -z "$REPO" ]] && $CREATE; then
		error 'No Git-parallel repository name was specified.'
		return 4
	fi
	if [[ ! -z "$REPO" && ! -d $GP_DIR/$REPO ]] && ! $CREATE; then
		errcat <<-EOF
The Git-parallel repository '$REPO' does not exist in '$PWD'. Specify the -c /
--create option to create the repository.
		EOF
		return 5
	fi

	# Guard against dubious input.
	local ACTIVE=`list --active 2>/dev/null`
	if [[ ! -z "$REPO" && -d .git && -z "$ACTIVE" ]] &&
	! { $CLOBBER || { $CREATE && $MIGRATE; }; }; then
		errcat <<-'EOF'
There exists an active Git repository that is not a symlink to a Git-parallel
repository. By switching to another Git-parallel repository, the contents of
your active Git repository WILL BE LOST! To approve the removal, specify the -C
/ --clobber option.
		EOF
		return 6
	fi

	# Guard against harmless input.
	if ! $CREATE && [[ $REPO = $ACTIVE ]]; then
		if [[ -z "$REPO" ]]; then
			info "There is no Git-parallel repository to deactivate." $REPO
		else
			info "The Git-parallel repository '%s' is already active." $REPO
		fi
		return 0
	fi

	# Perform the main routine.
	if $CREATE; then
		export OLDPWD
		(cd "$OLDPWD" &&
		create `$MIGRATE && printf '%s\n' --migrate` $REPO) || return 7
	fi

	if [[ ! -z "$ACTIVE" ]]; then
		rm $GP_DIR/$ACTIVE &&
		mv -T .git $GP_DIR/$ACTIVE || return 8
	else
		rm -rf .git || return 9
	fi

	if [[ ! -z "$REPO" ]]; then
		mv -T $GP_DIR/$REPO .git &&
		(cd $GP_DIR && ln -s ../.git $REPO) || return 10
	fi

	# Print additional information.
	if $CREATE; then
		info "Switched to a new Git-parallel repository '%s'." $REPO
	else
		if [[ -z "$REPO" ]]; then
			info "Deactivated the Git-parallel repository '%s'." $ACTIVE
		else
			info "Switched to the Git-parallel repository '%s'." $REPO
		fi
	fi
}

newSubcommand     \
	FUNCTION=do_cmd \
	NAME=do         \
	LOCK=exclusive  \
	SYNOPSIS=\
'[-f | --force] REPO... -- COMMAND' \
	USAGE=\
"switches to every specified Git-parallel REPOsitory and executes 'git
COMMAND'. Should 'git COMMAND' exit with a non-zero exit code, the
'$GP_EXECUTABLE do' command will be interrupted prematurely, unless the -f /
--force option is specified. After the command has ended, the original Git
repository will be restored."

do_cmd() {
	local REPOS=()
	local COMMAND=()
	local FORCE=false

	# Collect the options and repositories.
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-f)														;& # fall-through
			--force)	FORCE=true					;;
			--)				shift; break				;;
			 *)				checkName "$1" || return 1
								REPOS+=($1)					;;
		esac
		shift
	done

	# Collect the Git command.
	while [[ $# -gt 0 ]]; do
		COMMAND+=("$1")
		shift
	done

	# Guard against bad input.
	local PREVIOUS_PWD="$PWD"
	jumpToRoot $GP_DIR || return 3
	if [[ ${#REPOS[@]} = 0 ]]; then
		error 'No Git-parallel repositories were specified.'
		return 4
	fi
	local REPO; for REPO in ${REPOS[@]}; do
		if [[ ! -d $GP_DIR/$REPO ]]; then
			error "The Git-parallel repository '%s' does not exist in '%s'." \
				$REPO "$PWD"
			return 5
		fi
	done

	# Perform the main routine.
	local FAILED=false
	stash &&
	for REPO in ${REPOS[@]}; do
		if ! checkout $REPO && ! $FORCE; then
			FAILED=true
			break
		fi
		if (cd "$PREVIOUS_PWD" && git "${COMMAND[@]}"); then :; else
			local COMMAND_STRING="${COMMAND[@]}"
			error "The command 'git %s' failed." "$COMMAND_STRING"
			if ! $FORCE; then
				FAILED=true
				break
			fi
		fi
	done || FAILED=true
	
	if ! restore || $FAILED; then
		return 6
	fi
}

newSubcommand      \
	FUNCTION=foreach \
	NAME=fe,foreach  \
	LOCK=exclusive   \
	SYNOPSIS=\
'[-f | --force] COMMAND' \
	USAGE=\
"switches to every Git-parallel REPOsitory and executes 'git COMMAND'. Should
'git COMMAND' exit with a non-zero exit code, the '$GP_EXECUTABLE foreach'
command will be interrupted prematurely, unless the -f / --force option is
specified. After the command has ended, the original Git repository will be
restored."

foreach() {
	local COMMAND=()
	local FORCE=false

	# Collect the options.
	case "$1" in
		-f)														;& # fall-through
		--force)	FORCE=true					;;
		 *)				COMMAND+=("$1")			;;
	esac
	shift

	# Collect the Git command.
	while [[ $# -gt 0 ]]; do
		COMMAND+=("$1")
		shift
	done

	# Perform the main routine.
	local IFS="$OLDIFS"
	local LIST=($(list))
	do_cmd `$FORCE && echo --force` ${LIST[*]} -- "${COMMAND[@]}"
}

# == The main routine ==

main "$@"
