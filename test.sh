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
	[[ `grep '^\.gitparallel' <.gitignore | wc -l` = 1 ]] || return 4
	mkdir -p foo/bar foo/.git || return 5
	cd foo/bar || return 6
	[[ -e ../.gitignore ]] && return 7
	printf '.gitparallel\n' >../.gitignore
	../../gp init --follow-git -u || return 8
	[[ -e ../.gitignore ]] || return 9
	[[ `grep '^\.gitparallel' <../.gitignore | wc -l` = 1 ]] || return 4
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
	./gp create a b/c && return 2
	./gp create 'a
	             b' c d && return 3
	./gp create . b c d && return 4
	./gp create a. b c || return 5
	{ rm -rf .gitparallel && ./gp init; } || return 6
	./gp create a b --bogus d && return 7
	./gp create a b bo-gus d || return 8
	./gp create a b 'c d' && return 9
	./gp create a b 'c	d' && return 10
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
	mv -T .gitparallel/a .git || return 2
	cd .gitparallel || return 3
	ln -s ../.git a || return 4
	cd .. || return 5
	./gp remove a && return 6
	./gp remove -f a || return 7
	mv -T .gitparallel/b .git || return 8
	cd .gitparallel || return 9
	ln -s ../.git b || return 10
	cd .. || return 11
	./gp remove b && return 12
	./gp remove --force b || return 13
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
	mv -T .gitparallel/a .git || return 6
	cd .gitparallel || return 7
	ln -s ../.git a || return 8
	cd .. || return 9
	./gp list -H | grep -q '^\* ' || return 10
	./gp list --human-readable | grep -q '^\* ' || return 11
	./gp list -p | grep -q '^\* ' && return 12
	./gp list --porcelain | grep -q '^ \*' && return 13
	return 0
}

### Test the correct handline of the -a / --active options.
TESTS+=(list_active)
list_active() {
	./gp init

	./gp list --active && return 1
	./gp list -a && return 2
	[[ -z "`./gp list --active`" ]] || return 3
	[[ -z "`./gp list -a`" ]] || return 4

	./gp create a || return 5
	[[ -z "`./gp list --active`" ]] || return 6
	[[ -z "`./gp list -a`" ]] || return 7
	./gp list --active && return 8
	./gp list -a && return 9

	mv -T .gitparallel/a .git || return 10
	(cd .gitparallel && ln -s ../.git a) || return 11
	./gp list --active || return 12
	./gp list -a || return 13
	[[ "`./gp list --active`" = a ]] || return 14
	[[ "`./gp list -a`" = a ]] || return 15

	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(list_checkNames)
list_checkNames() {
	./gp init
	./gp create a b c d || return 1
	mkdir -- .gitparallel/'a
												 b' \
					 .gitparallel/.a \
					 .gitparallel/--bogus \
					 .gitparallel/'c d' \
					 .gitparallel/'c	d' || return 2
	[[ `./gp list | wc -l` = 4 ]] || return 3
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
	rm .gitparallel/b || return 4
	mv -T .git .gitparallel/b || return 5
	mkdir .git || return 6
	./gp checkout a && return 7
	./gp checkout --clobber a || return 8
	rm .gitparallel/a || return 9
	mv -T .git .gitparallel/a || return 10
	mkdir .git || return 11
	./gp checkout b && return 12
	./gp checkout -C b || return 13
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
	rm .gitparallel/a || return 3
	mv -T .git .gitparallel/a || return 4
	mkdir .git || return 5
	./gp checkout b && return 6
	./gp checkout --create b && return 7
	./gp checkout --migrate b && return 8
	./gp checkout --create --migrate b || return 9
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

	rm .gitparallel/a || return 10
	mv -T .git .gitparallel/a || return 11
	mkdir .git || return 12
	touch .git/foobar || return 13

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
	./gp checkout --create 'a
	                        b' && return 3
	./gp checkout --create . && return 4
	./gp checkout --create a. || return 5
	./gp checkout --create --bogus && return 6
	./gp checkout --create bo-gus || return 7
	./gp checkout --create a b 'c d' && return 8
	./gp checkout --create a b 'c	d' && return 9
	return 0
}

## == Tests for the `do` subcommand ==
### Test the correct functionality of the command.
TESTS+=(do_cmd)
do_cmd() {
	./gp init
	./gp create a b c || return 1
	./gp do a b c -- log && return 2
	touch file
	./gp do a b c -- add file || return 3
	./gp do a b c -- commit -am 'initial commit' || return 3
	./gp do a b c -- log || return 4
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(do_force)
do_force() {
	./gp init
	./gp create a b c || return 1
	./gp do a b c -- log && return 2
	./gp do -f a b c -- log || return 3
	./gp do a b c --force -- log || return 4
	./gp do a b c -- log && return 5
	return 0
}

### Test that the command fails without `init`.
TESTS+=(do_noinit)
do_noinit() {
	./gp init
	./gp create a b c || return 1
	rm -r .gitparallel
	./gp do `./gp list` -- status --porcelain && return 2
	return 0
}

### Test that the command does not change the current working directory.
TESTS+=(do_pwd)
do_pwd() {
	./gp init
	./gp checkout --create master || return 1
	mkdir aaa
	cd aaa
	touch bbb
	../gp do master -- add bbb || return 2
	return 0
}

### Test the restoration of the previous environment.
TESTS+=(do_restore)
do_restore() {
	./gp init
	./gp create a b c || return 1
	./gp do `./gp list` -- status --porcelain || return 2
	[[ -e .git ]] && return 3
	mkdir .git
	touch .git/foobar
	./gp do `./gp list` -- status --porcelain || return 4
	./gp do `./gp list` -- status --porcelain || return 5
	[[ -e .git/foobar ]] || return 6
	return 0
}

### Test the non-expansion of arguments.
TESTS+=(do_eval)
do_eval() {
	./gp init
	./gp create a b c || return 1
	./gp do `./gp list` -- status --porcelain '(' || return 2
	return 0
}

## == Tests for the `foreach` subcommand ==
### Test the correct functionality of the command.
TESTS+=(foreach)
foreach() {
	./gp init
	./gp create a b c || return 1
	./gp foreach log && return 2
	touch file
	./gp foreach add file || return 3
	./gp foreach commit -am 'initial commit' || return 3
	./gp foreach log || return 4
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(foreach_alias)
foreach_alias() {
	./gp init
	./gp create a b c || return 1
	./gp fe log && return 2
	touch file
	./gp fe add file || return 3
	./gp fe commit -am 'initial commit' || return 3
	./gp fe log || return 4
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(foreach_force)
foreach_force() {
	./gp init
	./gp create a b c || return 1
	./gp foreach log && return 2
	./gp foreach -f log || return 3
	./gp foreach --force log || return 4
	./gp foreach log && return 5
	return 0
}

### Test that the command fails without `init`.
TESTS+=(foreach_noinit)
foreach_noinit() {
	./gp init
	./gp create a b c || return 1
	rm -r .gitparallel
	./gp foreach status --porcelain && return 2
	return 0
}

### Test that the command does not change the current working directory.
TESTS+=(foreach_pwd)
foreach_pwd() {
	./gp init
	./gp checkout --create master || return 1
	mkdir aaa
	cd aaa
	touch bbb
	../gp foreach add bbb || return 2
	return 0
}

### Test the restoration of the previous environment.
TESTS+=(foreach_restore)
foreach_restore() {
	./gp init
	./gp create a b c || return 1
	./gp foreach status --porcelain || return 2
	[[ -e .git ]] && return 3
	mkdir .git
	touch .git/foobar
	./gp foreach status --porcelain || return 4
	./gp foreach status --porcelain || return 5
	[[ -e .git/foobar ]] || return 6
	return 0
}

### Test the non-expansion of arguments.
TESTS+=(foreach_eval)
foreach_eval() {
	./gp init
	./gp create a b c || return 1
	./gp foreach status --porcelain '(' || return 2
	return 0
}

## == Tests for the `upgrade` subcommand ==
### Test the output, when an upgrade from version <2.0.0 is needed.
TESTS+=(upgrade_sub_v2_0_0)
upgrade_sub_v2_0_0() {
	mkdir .gitparallel
	mkdir .gitparallel/{a,b,c}
	ln -s .gitparallel/a .git
	./gp upgrade || return 1
	./gp foreach status --porcelain || return 6
	[[ `gp list --active` = a ]] || return 7
	return 0
}

### Test the output, when an upgrade from version 2.0.0 is needed.
TESTS+=(upgrade_eq_v2_0_0)
upgrade_eq_v2_0_0() {
	mkdir .gitparallel
	mkdir .gitparallel/{a,b,c}
	ln -s .gitparallel/a .git
	printf '2.0.0\n' >.gitparallel/.version
	./gp upgrade || return 1
	./gp foreach status --porcelain && return 6
	[[ `gp list --active` = a ]] && return 7
	return 0
}

### Test the output, when an upgrade from version 3.0.0 is needed.
TESTS+=(upgrade_sup_v2_0_0)
upgrade_sup_v2_0_0() {
	mkdir .gitparallel
	mkdir .gitparallel/{a,b,c}
	ln -s .gitparallel/a .git
	printf '3.0.0\n' >.gitparallel/.version
	./gp upgrade && return 1
	./gp foreach status --porcelain && return 6
	[[ `gp list --active` = a ]] && return 7
	return 0
}

# == The main routine ==
trap 'rm -rf "$LOG" "$DIR"' EXIT
LOG="`mktemp`" &&
for TEST in "${TESTS[@]}"; do
	printf 'Running \033[1m%s\033[m ...' "$TEST"
	DIR="`mktemp -d`" &&
	{ if (cp gp "$DIR"/gp && cd "$DIR" && "$TEST" &>"$LOG"); then
		printf '\t\033[1m\033[32m[OK]\033[m\n'
	else
		printf '\t\033[1m\033[31m[FAILED: %d]\033[m\n' "$?"
		cat "$LOG"
		exit 1
	fi
	rm -rf "$DIR"; }
done
printf '\033[1m\033[32mAll passed!\033[m\n'
