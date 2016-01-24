#!/bin/bash
# == Test definitions ==
TESTS=()

## == Tests for the `init` subcommand ==
### Test the basic functionality of the command.
TESTS+=(init)
init() {
	[[ -d .gitparallel ]] && return 1
	./gp init || return 2
	[[ -d .gitparallel ]] || return 3
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(init_alias)
init_alias() {
	[[ -d .gitparallel ]] && return 1
	./gp i || return 2
	[[ -d .gitparallel ]] || return 3
	return 0
}

### Test the correct handling of the -F / --follow-git option.
TESTS+=(init_follow_git)
init_follow_git() {
	mkdir -p .git foo bar/.git bar/baz || return 1
	cd foo || return 2
	[[ -d .gitparallel ]] && return 3
	../gp init || return 4
	[[ -d .gitparallel ]] || return 5
	[[ -d ../.gitparallel ]] && return 6
	../gp init --follow-git || return 7
	[[ -d ../.gitparallel ]] || return 8
	cd ../bar/baz || return 9
	[[ -d ../.gitparallel ]] && return 10
	../../gp init -F || return 11
	[[ -d ../.gitparallel ]] || return 12
	return 0
}

### Test the correct handling of the -u / --update-gitignore option.
TESTS+=(init_update_gitignore)
init_update_gitignore() {
	[[ -e .gitignore ]] && return 1
	./gp init --update-gitignore || return 2
	[[ -e .gitignore ]] || return 3
	grep -q '^\.gitparallel' <.gitignore || return 4
	mkdir -p foo/bar foo/.git || return 5
	cd foo/bar || return 6
	[[ -e ../.gitignore ]] && return 7
	../../gp init --follow-git -u || return 8
	[[ -e ../.gitignore ]] || return 9
	grep -q '^\.gitparallel' <../.gitignore || return 10
	return 0
}

### Test the correct handling of the -u / --update-gitignore option.
TESTS+=(init_update_gitignore_unnecessary)
init_update_gitignore_unnecessary() {
	[[ -e .gitignore ]] && return 1
	printf '.gitparallel\n' >.gitignore || return 2
	[[ "`wc -l <.gitignore`" = 1 ]] || return 3
	./gp init --update-gitignore || return 4
	[[ "`wc -l <.gitignore`" = 1 ]] || return 5
	return 0
}

### Test the correct handling of bogus input.
TESTS+=(init_bogus)
init_bogus() {
	./gp init bogus && return 1
	return 0
}

## == Tests for the `create` subcommand ==
### Test the basic functionality of the command.
TESTS+=(create)
create() {
	./gp init
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	./gp create a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	./gp create a b c && return 4
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 5
	./gp create d e f || return 6
	[[ "`ls .gitparallel | wc -l`" = 6 ]] || return 7
	return 0
}

### Test that the command fails without `init`.
TESTS+=(create_noinit)
create_noinit() {
	[[ ! -d .gitparallel ]] || return 1
	./gp create a b c && return 2
	[[ ! -d .gitparallel ]] || return 3
	return 0
}

### Test the correct handling of --.
TESTS+=(create_dbldash)
create_dbldash() {
	./gp init
	./gp create a b c -- d e || return 1
	[[ "`ls .gitparallel | wc -l`" = 5 ]] || return 2
	return 0
}

### Test the correct handling of empty input.
TESTS+=(create_empty)
create_empty() {
	./gp init
	./gp create && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(create_alias)
create_alias() {
	./gp init
	./gp cr a b c
}

### Test the correct handling of the -m / --migrate option.
TESTS+=(create_migrate)
create_migrate() {
	./gp init
	./gp create -m a b c && return 1
	./gp create --migrate a b c && return 2
	mkdir .git foo || return 3
	touch .git/foobar || return 4
	cd foo || return 5
	../gp init || return 6
	../gp create -m a b c || return 7
	[[ -e .gitparallel/a/foobar ]] || return 8
	[[ -e .gitparallel/b/foobar ]] || return 9
	[[ -e .gitparallel/c/foobar ]] || return 10
	../gp create --migrate a b c && return 11
	../gp create --migrate d e f || return 12
	[[ -e .gitparallel/d/foobar ]] || return 13
	[[ -e .gitparallel/e/foobar ]] || return 14
	[[ -e .gitparallel/f/foobar ]] || return 15
	../gp create -m d e f && return 16
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(create_checkNames)
create_checkNames() {
	./gp init
	./gp create a b c '' && return 1
	./gp create a b/c d && return 2
	./gp create . b c d && return 3
	./gp create a b --bogus d && return 4
	return 0
}

## == Tests for the `remove` subcommand ==
### Test the basic functionality of the command.
TESTS+=(remove)
remove() {
	./gp init
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	./gp create a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	./gp create d e f || return 4
	[[ "`ls .gitparallel | wc -l`" = 6 ]] || return 5
	./gp remove a c e || return 6
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 7
	./gp remove b d f || return 8
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 9
	return 0
}

### Test that the command fails without `init`.
TESTS+=(remove_noinit)
remove_noinit() {
	./gp init
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	./gp create a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	rmdir .gitparallel
	./gp remove a c e && return 4
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 5
	return 0
}

### Test the correct handling of --.
TESTS+=(remove_dbldash)
remove_dbldash() {
	./gp init
	./gp create a b c -- d e || return 1
	[[ "`ls .gitparallel | wc -l`" = 5 ]] || return 2
	./gp remove a b c -- d e || return 3
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 4
	return 0
}

### Test the correct handling of empty input.
TESTS+=(remove_empty)
remove_empty() {
	./gp init
	./gp remove && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(remove_alias)
remove_alias() {
	./gp init
	./gp rm a && return 1
	./gp create a || return 2
	./gp rm a || return 3
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(remove_force)
remove_force() {
	./gp init
	./gp create a b || return 1
	ln -s .gitparallel/a .git
	./gp remove a && return 2
	./gp remove -f a || return 3
	ln -s .gitparallel/b .git
	./gp remove b && return 4
	./gp remove --force b || return 5
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(remove_checkNames)
remove_checkNames() {
	./gp init
	./gp remove '' && return 1
	return 0
}

## == Tests for the `list` subcommand ==
### Test the basic functionality of the command.
TESTS+=(list)
list() {
	./gp init
	[[ "`./gp list | wc -l`" = 0 ]] || return 1
	./gp create a b c || return 2
	[[ "`./gp list | wc -l`" = 3 ]] || return 3
	./gp create d e f || return 4
	[[ "`./gp list | wc -l`" = 6 ]] || return 5
	./gp remove a c e || return 6
	[[ "`./gp list | wc -l`" = 3 ]] || return 7
	./gp remove b d f || return 8
	[[ "`./gp list | wc -l`" = 0 ]] || return 9
	return 0
}

### Test that the command fails without `init`.
TESTS+=(list_noinit)
list_noinit() {
	./gp list && return 1
	return 0
}

### Test the correct handling of bogus input.
TESTS+=(list_bogus)
list_bogus() {
	./gp init
	./gp bogus && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(list_alias)
list_alias() {
	./gp init
	./gp ls || return 1
	return 0
}

### Test the correct handling of the -p / --porcelain and -H / --human-readable
### options.
TESTS+=(list_porcelain)
list_porcelain() {
	./gp init
	./gp create a b c || return 1
	./gp list -H | grep -q '^\* ' && return 2
	./gp list --human-readable | grep -q '^\* ' && return 3
	./gp list -p | grep -q '^\* ' && return 4
	./gp list --porcelain | grep -q '^ \*' && return 5
	ln -s .gitparallel/a .git
	./gp list -H | grep -q '^\* ' || return 6
	./gp list --human-readable | grep -q '^\* ' || return 7
	./gp list -p | grep -q '^\* ' && return 8
	./gp list --porcelain | grep -q '^ \*' && return 9
	return 0
}

## == Tests for the `checkout` subcommand ==
### Test the basic functionality of the command.
TESTS+=(checkout)
checkout() {
	./gp init
	./gp checkout a && return 1
	./gp create a || return 2
	./gp checkout a || return 3
	./gp remove --force a || return 4
	./gp checkout a && return 5
	return 0
}

### Test that the command fails without `init`.
TESTS+=(checkout_noinit)
checkout_noinit() {
	./gp checkout a && return 1
	./gp create a && return 2
	./gp checkout a && return 3
	return 0
}

### Test the correct handling of the -C / --clobber option.
TESTS+=(checkout_clobber)
checkout_clobber() {
	./gp init
	./gp create a b || return 1
	./gp checkout a || return 2
	./gp checkout b || return 3
	rm .git
	mkdir .git
	./gp checkout a && return 4
	./gp checkout --clobber a || return 5
	rm .git
	mkdir .git
	./gp checkout b && return 6
	./gp checkout -C b || return 7
	return 0
}

### Test the correct handling of the -c / --create option.
TESTS+=(checkout_create)
checkout_create() {
	./gp init
	./gp checkout a && return 1
	./gp checkout --create a || return 2
	./gp checkout b && return 3
	./gp checkout -c b || return 4
	[[ "`./gp list | wc -l`" = 2 ]] || return 5
	return 0
}

### Test the correct handling of the -c / --create and -m / --migrate options.
TESTS+=(checkout_create_migrate)
checkout_create_migrate() {
	./gp init
	./gp checkout a && return 1
	./gp checkout --create a || return 2
	rm .git
	mkdir .git
	./gp checkout b && return 3
	./gp checkout --create b && return 4
	./gp checkout --migrate b && return 5
	./gp checkout --create --migrate b || return 6
	return 0
}

### Test the correct handling of empty input.
TESTS+=(checkout_empty)
checkout_empty() {
	./gp init
	./gp checkout --create && return 1
	return 0
}

### Test the correct handling of extraneous input.
TESTS+=(checkout_extra)
checkout_extra() {
	./gp init
	./gp checkout --create foo bar && return 1
	return 0
}

### Test the correct handling of --.
TESTS+=(checkout_dbldash)
checkout_dbldash() {
	./gp init
	./gp create a b c -- d e || return 1
	./gp checkout -- d || return 2
	./gp checkout -- e || return 3
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(checkout_alias)
checkout_alias() {
	./gp init
	./gp co a && return 1
	./gp create a || return 2
	./gp co a || return 3
	./gp rm --force a || return 4
	./gp co a && return 5
	return 0
}

### Test the correct handling of the -m / --migrate option.
TESTS+=(checkout_migrate)
checkout_migrate() {
	./gp init
	./gp checkout --create -m a && return 1
	./gp checkout --create --migrate a && return 2
	mkdir .git foo || return 3
	touch .git/foobar || return 4
	cd foo || return 5
	../gp init || return 6
	../gp checkout --create -m a || return 7
	[[ -e .gitparallel/a/foobar ]] || return 8
	../gp checkout --create --migrate a && return 9
	rm .git || return 10
	mkdir .git
	touch .git/foobar
	../gp checkout --create --migrate b || return 7
	[[ -e .gitparallel/b/foobar ]] || return 8
	../gp checkout --create -m b && return 9
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(checkout_checkNames)
checkout_checkNames() {
	./gp init
	./gp checkout --create '' && return 1
	./gp checkout --create a/b && return 2
	./gp checkout --create . && return 3
	./gp checkout --create --bogus && return 4
	return 0
}

## == Tests for the `do` subcommand ==
### Test the correct functionality of the stdin repo input overload.
TESTS+=(do_cmd_stdin)
do_cmd_stdin() {
	./gp init
	./gp create a b c || return 1
	./gp list | ./gp do status --porcelain && return 2
	./gp list | ./gp do init || return 3
	./gp list | ./gp do status --porcelain || return 4
	return 0
}

### Test the correct functionality of the args repo input overload.
TESTS+=(do_cmd_args)
do_cmd_args() {
	./gp init
	./gp create a b c || return 1
	./gp do a b c -- status --porcelain && return 2
	./gp do a b c -- init || return 3
	./gp do a b c -- status --porcelain || return 4
	return 0
}

### Test that the command fails without `init`.
TESTS+=(do_noinit)
do_noinit() {
	./gp init
	./gp create a b c || return 1
	rm -r .gitparallel
	./gp list | ./gp do init && return 2
	return 0
}

### Test the restoration of the previous environment.
TESTS+=(do_restore)
do_restore() {
	./gp init
	./gp create a b c || return 1
	./gp list | ./gp do init || return 2
	./gp list | ./gp do status --porcelain || return 3
	[[ -e .git ]] && return 4
	mkdir .git
	touch .git/foobar
	./gp list | ./gp do status --porcelain || return 5
	./gp list | ./gp do status --porcelain || return 6
	[[ -e .git/foobar ]] || return 7
	return 0
}

### Test the command's locking mechanism.
TESTS+=(do_lock)
do_lock() {
	./gp init
	./gp create a b c || return 1
	./gp list | ./gp do init || return 2
	touch .gitparallel/.lock || return 3
	./gp list | ./gp do init && return 4
	return 0
}

# == The main routine ==
LOG="`mktemp`" &&
for TEST in "${TESTS[@]}"; do
	printf 'Running \033[1m%s\033[m ...' "$TEST"
	DIR="`mktemp -d`" &&
	{ if (cp gp "$DIR"/gp && cd "$DIR" && "$TEST" &>"$LOG"); then
		printf '\t\033[1m\033[32m[OK]\033[m\n'
	else
		printf '\t\033[1m\033[31m[FAILED: %d]\033[m\n' "$?"
		cat "$LOG"
		rm -rf "$DIR" "$LOG"
		exit 1
	fi
	rm -rf "$DIR"; }
done
rm -rf "$LOG"
printf '\033[1m\033[32mAll passed!\033[m\n'
