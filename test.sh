#!/bin/bash
# == Test definitions ==
TESTS=()

## == Tests for the `init` subcommand ==
### Test the basic functionality of the command.
TESTS+=(init)
init() {
	[[ -d .gitparallel ]] && return 1
	$GP init || return 2
	[[ -d .gitparallel ]] || return 3
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(init_alias)
init_alias() {
	[[ -d .gitparallel ]] && return 1
	$GP i || return 2
	[[ -d .gitparallel ]] || return 3
	return 0
}

### Test the correct handling of the -F / --follow-git option.
TESTS+=(init_follow_git)
init_follow_git() {
	mkdir -p .git foo bar/.git bar/baz || return 1
	cd foo || return 2
	[[ -d .gitparallel ]] && return 3
	.$GP init || return 4
	[[ -d .gitparallel ]] || return 5
	[[ -d ../.gitparallel ]] && return 6
	.$GP init --follow-git || return 7
	[[ -d ../.gitparallel ]] || return 8
	cd ../bar/baz || return 9
	[[ -d ../.gitparallel ]] && return 10
	../.$GP init -F || return 11
	[[ -d ../.gitparallel ]] || return 12
	return 0
}

### Test the correct handling of the -u / --update-gitignore option.
TESTS+=(init_update_gitignore)
init_update_gitignore() {
	[[ -e .gitignore ]] && return 1
	$GP init --update-gitignore || return 2
	[[ -e .gitignore ]] || return 3
	[[ `grep '^\.gitparallel' <.gitignore | wc -l` = 1 ]] || return 4
	mkdir -p foo/bar foo/.git || return 5
	cd foo/bar || return 6
	[[ -e ../.gitignore ]] && return 7
	printf '.gitparallel\n' >../.gitignore
	../.$GP init --follow-git -u || return 8
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
	$GP init --update-gitignore || return 4
	[[ "`wc -l <.gitignore`" = 1 ]] || return 5
	return 0
}

### Test the correct handling of bogus input.
TESTS+=(init_bogus)
init_bogus() {
	$GP init bogus && return 1
	return 0
}

## == Tests for the `create` subcommand ==
### Test the basic functionality of the command.
TESTS+=(create)
create() {
	$GP init
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	$GP create a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	$GP create a b c && return 4
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 5
	$GP create d e f || return 6
	[[ "`ls .gitparallel | wc -l`" = 6 ]] || return 7
	return 0
}

### Test that the command fails without `init`.
TESTS+=(create_noinit)
create_noinit() {
	[[ ! -d .gitparallel ]] || return 1
	$GP create a b c && return 2
	[[ ! -d .gitparallel ]] || return 3
	return 0
}

### Test the correct handling of --.
TESTS+=(create_dbldash)
create_dbldash() {
	$GP init
	$GP create a b c -- d e || return 1
	[[ "`ls .gitparallel | wc -l`" = 5 ]] || return 2
	return 0
}

### Test the correct handling of empty input.
TESTS+=(create_empty)
create_empty() {
	$GP init
	$GP create && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(create_alias)
create_alias() {
	$GP init
	$GP cr a b c
}

### Test the correct handling of the -m / --migrate option.
TESTS+=(create_migrate)
create_migrate() {
	$GP init
	$GP create -m a b c && return 1
	$GP create --migrate a b c && return 2
	mkdir .git foo || return 3
	touch .git/foobar || return 4
	cd foo || return 5
	.$GP init || return 6
	.$GP create -m a b c || return 7
	[[ -e .gitparallel/a/foobar ]] || return 8
	[[ -e .gitparallel/b/foobar ]] || return 9
	[[ -e .gitparallel/c/foobar ]] || return 10
	.$GP create --migrate a b c && return 11
	.$GP create --migrate d e f || return 12
	[[ -e .gitparallel/d/foobar ]] || return 13
	[[ -e .gitparallel/e/foobar ]] || return 14
	[[ -e .gitparallel/f/foobar ]] || return 15
	.$GP create -m d e f && return 16
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(create_checkNames)
create_checkNames() {
	$GP init
	$GP create a b c '' && return 1
	$GP create a b/c && return 2
	$GP create 'a
	             b' c d && return 3
	$GP create . b c d && return 4
	$GP create a. b c || return 5
	{ rm -rf .gitparallel && $GP init; } || return 6
	$GP create a b --bogus d && return 7
	$GP create a b bo-gus d || return 8
	$GP create a b 'c d' && return 9
	$GP create a b 'c	d' && return 10
	return 0
}

## == Tests for the `copy` subcommand ==
### Test the basic functionality of the command.
TESTS+=(copy)
copy() {
	$GP init
	$GP create a || return 1
	$GP copy a b || return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test that the command fails without `init`.
TESTS+=(copy_noinit)
copy_noinit() {
	$GP init
	$GP create a || return 1
	rm -r .gitparallel || return 2
	$GP copy a b && return 3
	return 0
}

### Test the correct handling of --.
TESTS+=(copy_dbldash)
copy_dbldash() {
	$GP init
	$GP create a || return 1
	$GP copy a -- b || return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test the correct handling of empty input.
TESTS+=(copy_empty)
copy_empty() {
	$GP init
	$GP copy && return 1
	return 0
}

### Test the correct handling of non-existent source directory.
TESTS+=(copy_bad_source)
copy_bad_source() {
	$GP init
	$GP create a || return 1
	$GP copy b c && return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] && return 4
	[[ -d .gitparallel/c ]] && return 5
	return 0
}

### Test the correct handling of extraneous input.
TESTS+=(copy_extra)
copy_extra() {
	$GP init
	$GP create a || return 1
	$GP copy a b c || return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] || return 4
	[[ -d .gitparallel/c ]] || return 5
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(copy_alias)
copy_alias() {
	$GP init
	$GP create a || return 1
	$GP cp a b || return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(copy_checkNames)
copy_checkNames() {
	$GP init
	$GP create a || return 1
	$GP copy a '' && return 2
	$GP copy a b/c && return 3
	$GP copy a 'a
	             b' && return 4
	$GP copy a . && return 5
	$GP copy a a. || return 6
	$GP copy a. --bogus && return 7
	$GP copy a. bo-gus || return 8
	$GP copy bo-gus 'c d' && return 9
	$GP copy bo-gus 'c	d' && return 10
	[[ -d .gitparallel/bo-gus ]] || return 11
	return 0
}

### Test the inferrence capabilities of the command.
TESTS+=(copy_infer)
copy_infer() {
	$GP init
	$GP create a || return 1
	mv -T .gitparallel/a .git || return 2
	cd .gitparallel || return 3
	ln -s ../.git a || return 4
	cd .. || return 5
	$GP copy b || return 6
	[[ -d .gitparallel/a ]] || return 7
	[[ -d .gitparallel/b ]] || return 8
	rm -r .gitparallel/a || return 9
	mv -T .git .gitparallel/a || return 10
	$GP copy c && return 11
	[[ -d .gitparallel/a ]] || return 12
	[[ -d .gitparallel/b ]] || return 13
	[[ -d .gitparallel/c ]] && return 14
	return 0
}

### Test the correct handling of copying a repo to itself.
TESTS+=(copy_toself)
copy_toself() {
	$GP init
	$GP create a || return 1
	$GP copy a && return 2
	$GP copy a a && return 3
	return 0
}

### Test the correct handling of specifying duplicate repos.
TESTS+=(copy_duplicates)
copy_duplicates() {
	$GP init
	$GP create a || return 1
	$GP copy a b b c c b c || return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] || return 4
	[[ -d .gitparallel/c ]] || return 5
	return 0
}

### Test the correct handling of the -C / --clobber option.
TESTS+=(copy_clobber)
copy_clobber() {
	$GP init
	$GP create a b c || return 1
	touch .gitparallel/a/fileA
	touch .gitparallel/b/fileB
	$GP copy a b && return 2
	[[ -e .gitparallel/a/fileA ]] || return 3
	[[ -e .gitparallel/a/fileB ]] && return 4
	[[ -e .gitparallel/b/fileA ]] && return 5
	[[ -e .gitparallel/b/fileB ]] || return 6
	[[ -d .gitparallel/c ]] || return 7
	$GP copy --clobber a b || return 8
	[[ -e .gitparallel/a/fileA ]] || return 9
	[[ -e .gitparallel/a/fileB ]] && return 10
	[[ -e .gitparallel/b/fileA ]] || return 11
	[[ -e .gitparallel/b/fileB ]] && return 12
	[[ -d .gitparallel/c ]] || return 13
	$GP copy -C b c || return 14
	[[ -e .gitparallel/a/fileA ]] || return 15
	[[ -e .gitparallel/a/fileB ]] && return 16
	[[ -e .gitparallel/b/fileA ]] || return 17
	[[ -e .gitparallel/b/fileB ]] && return 18
	[[ -e .gitparallel/c/fileA ]] || return 19
	[[ -e .gitparallel/c/fileB ]] && return 20
	return 0
}

## == Tests for the `move` subcommand ==
### Test the basic functionality of the command.
TESTS+=(move)
move() {
	$GP init
	$GP create a || return 1
	$GP move a b || return 2
	[[ -d .gitparallel/a ]] && return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test that the command fails without `init`.
TESTS+=(move_noinit)
move_noinit() {
	$GP init
	$GP create a || return 1
	rm -r .gitparallel || return 2
	$GP move a b && return 3
	return 0
}

### Test the correct handling of --.
TESTS+=(move_dbldash)
move_dbldash() {
	$GP init
	$GP create a || return 1
	$GP move a -- b || return 2
	[[ -d .gitparallel/a ]] && return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test the correct handling of empty input.
TESTS+=(move_empty)
move_empty() {
	$GP init
	$GP move && return 1
	return 0
}

### Test the correct handling of non-existent source directory.
TESTS+=(move_bad_source)
move_bad_source() {
	$GP init
	$GP create a || return 1
	$GP move b c && return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] && return 4
	[[ -d .gitparallel/c ]] && return 5
	return 0
}

### Test the correct handling of extraneous input.
TESTS+=(move_extra)
move_extra() {
	$GP init
	$GP create a || return 1
	$GP move a b c && return 2
	[[ -d .gitparallel/a ]] || return 3
	[[ -d .gitparallel/b ]] && return 4
	[[ -d .gitparallel/c ]] && return 5
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(move_alias_mv)
move_alias_mv() {
	$GP init
	$GP create a || return 1
	$GP mv a b || return 2
	[[ -d .gitparallel/a ]] && return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(move_alias_rename)
move_alias_rename() {
	$GP init
	$GP create a || return 1
	$GP rename a b || return 2
	[[ -d .gitparallel/a ]] && return 3
	[[ -d .gitparallel/b ]] || return 4
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(move_checkNames)
move_checkNames() {
	$GP init
	$GP create a || return 1
	$GP move a '' && return 2
	$GP move a b/c && return 3
	$GP move a 'a
	             b' && return 4
	$GP move a . && return 5
	$GP move a a. || return 6
	$GP move a. --bogus && return 7
	$GP move a. bo-gus || return 8
	$GP move bo-gus 'c d' && return 9
	$GP move bo-gus 'c	d' && return 10
	[[ -d .gitparallel/bo-gus ]] || return 11
	return 0
}

### Test the inferrence capabilities of the command.
TESTS+=(move_infer)
move_infer() {
	$GP init
	$GP create a || return 1
	mv -T .gitparallel/a .git || return 2
	cd .gitparallel || return 3
	ln -s ../.git a || return 4
	cd .. || return 5
	$GP move b || return 6
	[[ -d .gitparallel/a ]] && return 7
	[[ -d .gitparallel/b ]] || return 8
	rm -r .gitparallel/b || return 9
	mv -T .git .gitparallel/b || return 10
	$GP move c && return 11
	[[ -d .gitparallel/a ]] && return 12
	[[ -d .gitparallel/b ]] || return 13
	[[ -d .gitparallel/c ]] && return 14
	return 0
}

### Test the correct handling of moving a repo to itself.
TESTS+=(move_toself)
move_toself() {
	$GP init
	$GP create a || return 1
	$GP move a && return 2
	$GP move a a && return 3
	return 0
}

### Test the correct handling of the -C / --clobber option.
TESTS+=(move_clobber)
move_clobber() {
	$GP init
	$GP create a b c || return 1
	touch .gitparallel/a/test || return 2
	$GP move a b && return 3
	$GP move --clobber a b || return 4
	[[ -d .gitparallel/a ]] && return 5
	[[ -e .gitparallel/b/test ]] || return 6
	[[ -e .gitparallel/c/test ]] && return 7
	$GP move -C b c || return 8
	[[ -d .gitparallel/a ]] && return 9
	[[ -d .gitparallel/b ]] && return 10
	[[ -e .gitparallel/c/test ]] || return 11
	return 0
}

## == Tests for the `remove` subcommand ==
### Test the basic functionality of the command.
TESTS+=(remove)
remove() {
	$GP init
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	$GP create a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	$GP create d e f || return 4
	[[ "`ls .gitparallel | wc -l`" = 6 ]] || return 5
	$GP remove a c e || return 6
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 7
	$GP remove b d f || return 8
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 9
	return 0
}

### Test that the command fails without `init`.
TESTS+=(remove_noinit)
remove_noinit() {
	$GP init
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	$GP create a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	rmdir .gitparallel
	$GP remove a c e && return 4
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 5
	return 0
}

### Test the correct handling of --.
TESTS+=(remove_dbldash)
remove_dbldash() {
	$GP init
	$GP create a b c -- d e || return 1
	[[ "`ls .gitparallel | wc -l`" = 5 ]] || return 2
	$GP remove a b c -- d e || return 3
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 4
	return 0
}

### Test the correct handling of empty input.
TESTS+=(remove_empty)
remove_empty() {
	$GP init
	$GP remove && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(remove_alias)
remove_alias() {
	$GP init
	$GP rm a && return 1
	$GP create a || return 2
	$GP rm a || return 3
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(remove_force)
remove_force() {
	$GP init
	$GP create a b || return 1
	mv -T .gitparallel/a .git || return 2
	cd .gitparallel || return 3
	ln -s ../.git a || return 4
	cd .. || return 5
	$GP remove a && return 6
	$GP remove -f a || return 7
	mv -T .gitparallel/b .git || return 8
	cd .gitparallel || return 9
	ln -s ../.git b || return 10
	cd .. || return 11
	$GP remove b && return 12
	$GP remove --force b || return 13
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(remove_checkNames)
remove_checkNames() {
	$GP init
	$GP remove '' && return 1
	return 0
}

## == Tests for the `list` subcommand ==
### Test the basic functionality of the command.
TESTS+=(list)
list() {
	$GP init
	[[ "`$GP list | wc -l`" = 0 ]] || return 1
	$GP create a b c || return 2
	[[ "`$GP list | wc -l`" = 3 ]] || return 3
	$GP create d e f || return 4
	[[ "`$GP list | wc -l`" = 6 ]] || return 5
	$GP remove a c e || return 6
	[[ "`$GP list | wc -l`" = 3 ]] || return 7
	$GP remove b d f || return 8
	[[ "`$GP list | wc -l`" = 0 ]] || return 9
	return 0
}

### Test that the command fails without `init`.
TESTS+=(list_noinit)
list_noinit() {
	$GP list && return 1
	return 0
}

### Test the correct handling of bogus input.
TESTS+=(list_bogus)
list_bogus() {
	$GP init
	$GP bogus && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(list_alias)
list_alias() {
	$GP init
	$GP ls || return 1
	return 0
}

### Test the correct handling of the -p / --porcelain and -H / --human-readable
### options.
TESTS+=(list_porcelain)
list_porcelain() {
	$GP init
	$GP create a b c || return 1
	$GP list -H | grep -q '^\* ' && return 2
	$GP list --human-readable | grep -q '^\* ' && return 3
	$GP list -p | grep -q '^\* ' && return 4
	$GP list --porcelain | grep -q '^ \*' && return 5
	mv -T .gitparallel/a .git || return 6
	cd .gitparallel || return 7
	ln -s ../.git a || return 8
	cd .. || return 9
	$GP list -H | grep -q '^\* ' || return 10
	$GP list --human-readable | grep -q '^\* ' || return 11
	$GP list -p | grep -q '^\* ' && return 12
	$GP list --porcelain | grep -q '^ \*' && return 13
	return 0
}

### Test the correct handline of the -a / --active options.
TESTS+=(list_active)
list_active() {
	$GP init

	$GP list --active && return 1
	$GP list -a && return 2
	[[ -z "`$GP list --active`" ]] || return 3
	[[ -z "`$GP list -a`" ]] || return 4

	$GP create a || return 5
	[[ -z "`$GP list --active`" ]] || return 6
	[[ -z "`$GP list -a`" ]] || return 7
	$GP list --active && return 8
	$GP list -a && return 9

	mv -T .gitparallel/a .git || return 10
	(cd .gitparallel && ln -s ../.git a) || return 11
	$GP list --active || return 12
	$GP list -a || return 13
	[[ "`$GP list --active`" = a ]] || return 14
	[[ "`$GP list -a`" = a ]] || return 15

	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(list_checkNames)
list_checkNames() {
	$GP init
	$GP create a b c d || return 1
	mkdir -- .gitparallel/'a
												 b' \
					 .gitparallel/.a \
					 .gitparallel/--bogus \
					 .gitparallel/'c d' \
					 .gitparallel/'c	d' || return 2
	[[ `$GP list | wc -l` = 4 ]] || return 3
	return 0
}

## == Tests for the `checkout` subcommand ==
### Test the basic functionality of the command.
TESTS+=(checkout)
checkout() {
	$GP init
	$GP checkout a && return 1
	$GP create a || return 2
	$GP checkout a || return 3
	$GP remove --force a || return 4
	$GP checkout a && return 5
	return 0
}

### Test that the command fails without `init`.
TESTS+=(checkout_noinit)
checkout_noinit() {
	$GP checkout a && return 1
	$GP create a && return 2
	$GP checkout a && return 3
	return 0
}

### Test the correct handling of the -C / --clobber option.
TESTS+=(checkout_clobber)
checkout_clobber() {
	$GP init
	$GP create a b || return 1
	$GP checkout a || return 2
	$GP checkout b || return 3
	rm .gitparallel/b || return 4
	mv -T .git .gitparallel/b || return 5
	mkdir .git || return 6
	$GP checkout a && return 7
	$GP checkout --clobber a || return 8
	rm .gitparallel/a || return 9
	mv -T .git .gitparallel/a || return 10
	mkdir .git || return 11
	$GP checkout b && return 12
	$GP checkout -C b || return 13
	return 0
}

### Test the correct handling of the -c / --create option.
TESTS+=(checkout_create)
checkout_create() {
	$GP init
	$GP checkout a && return 1
	$GP checkout --create a || return 2
	$GP checkout b && return 3
	$GP checkout -c b || return 4
	[[ "`$GP list | wc -l`" = 2 ]] || return 5
	return 0
}

### Test the correct handling of the -c / --create and -m / --migrate options.
TESTS+=(checkout_create_migrate)
checkout_create_migrate() {
	$GP init
	$GP checkout a && return 1
	$GP checkout --create a || return 2
	rm .gitparallel/a || return 3
	mv -T .git .gitparallel/a || return 4
	mkdir .git || return 5
	$GP checkout b && return 6
	$GP checkout --create b && return 7
	$GP checkout --migrate b && return 8
	$GP checkout --create --migrate b || return 9
	return 0
}

### Test the correct handling of empty input.
TESTS+=(checkout_empty)
checkout_empty() {
	$GP init
	$GP checkout --create abc || return 1
	[[ -d .git && -L .gitparallel/abc ]] || return 2
	$GP checkout || return 3
	[[ ! -d .git && -d .gitparallel/abc ]] || return 4
	return 0
}

### Test the correct handling of extraneous input.
TESTS+=(checkout_extra)
checkout_extra() {
	$GP init
	$GP checkout --create foo bar && return 1
	return 0
}

### Test the correct handling of --.
TESTS+=(checkout_dbldash)
checkout_dbldash() {
	$GP init
	$GP create a b c -- d e || return 1
	$GP checkout -- d || return 2
	$GP checkout -- e || return 3
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(checkout_alias)
checkout_alias() {
	$GP init
	$GP co a && return 1
	$GP create a || return 2
	$GP co a || return 3
	$GP rm --force a || return 4
	$GP co a && return 5
	return 0
}

### Test the correct handling of the -m / --migrate option.
TESTS+=(checkout_migrate)
checkout_migrate() {
	$GP init
	$GP checkout --create -m a && return 1
	$GP checkout --create --migrate a && return 2
	mkdir .git foo || return 3
	touch .git/foobar || return 4
	cd foo || return 5
	.$GP init || return 6
	.$GP checkout --create -m a || return 7
	[[ -e .gitparallel/a/foobar ]] || return 8
	.$GP checkout --create --migrate a && return 9

	rm .gitparallel/a || return 10
	mv -T .git .gitparallel/a || return 11
	mkdir .git || return 12
	touch .git/foobar || return 13

	.$GP checkout --create --migrate b || return 7
	[[ -e .gitparallel/b/foobar ]] || return 8
	.$GP checkout --create -m b && return 9
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(checkout_checkNames)
checkout_checkNames() {
	$GP init
	$GP checkout --create '' && return 1
	$GP checkout --create a/b && return 2
	$GP checkout --create 'a
	                        b' && return 3
	$GP checkout --create . && return 4
	$GP checkout --create a. || return 5
	$GP checkout --create --bogus && return 6
	$GP checkout --create bo-gus || return 7
	$GP checkout --create a b 'c d' && return 8
	$GP checkout --create a b 'c	d' && return 9
	return 0
}

## == Tests for the `do` subcommand ==
### Test the correct functionality of the command.
TESTS+=(do_cmd)
do_cmd() {
	$GP init
	$GP create a b c || return 1
	$GP do a b c -- log && return 2
	touch file
	$GP do a b c -- add file || return 3
	$GP do a b c -- commit -am 'initial commit' || return 3
	$GP do a b c -- log || return 4
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(do_force)
do_force() {
	$GP init
	$GP create a b c || return 1
	$GP do a b c -- log && return 2
	$GP do -f a b c -- log || return 3
	$GP do a b c --force -- log || return 4
	$GP do a b c -- log && return 5
	return 0
}

### Test that the command fails without `init`.
TESTS+=(do_noinit)
do_noinit() {
	$GP init
	$GP create a b c || return 1
	rm -r .gitparallel
	$GP do `$GP list` -- status --porcelain && return 2
	return 0
}

### Test that the command does not change the current working directory.
TESTS+=(do_pwd)
do_pwd() {
	$GP init
	$GP checkout --create master || return 1
	mkdir aaa
	cd aaa
	touch bbb
	.$GP do master -- add bbb || return 2
	return 0
}

### Test the restoration of the previous environment.
TESTS+=(do_restore)
do_restore() {
	$GP init
	$GP create a b c || return 1
	$GP do `$GP list` -- status --porcelain || return 2
	[[ -e .git ]] && return 3
	mkdir .git
	touch .git/foobar
	$GP do `$GP list` -- status --porcelain || return 4
	$GP do `$GP list` -- status --porcelain || return 5
	[[ -e .git/foobar ]] || return 6
	return 0
}

### Test the non-expansion of arguments.
TESTS+=(do_eval)
do_eval() {
	$GP init
	$GP create a b c || return 1
	$GP do `$GP list` -- status --porcelain '(' || return 2
	return 0
}

## == Tests for the `foreach` subcommand ==
### Test the correct functionality of the command.
TESTS+=(foreach)
foreach() {
	$GP init
	$GP create a b c || return 1
	$GP foreach log && return 2
	touch file
	$GP foreach add file || return 3
	$GP foreach commit -am 'initial commit' || return 3
	$GP foreach log || return 4
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(foreach_alias)
foreach_alias() {
	$GP init
	$GP create a b c || return 1
	$GP fe log && return 2
	touch file
	$GP fe add file || return 3
	$GP fe commit -am 'initial commit' || return 3
	$GP fe log || return 4
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(foreach_force)
foreach_force() {
	$GP init
	$GP create a b c || return 1
	$GP foreach log && return 2
	$GP foreach -f log || return 3
	$GP foreach --force log || return 4
	$GP foreach log && return 5
	return 0
}

### Test that the command fails without `init`.
TESTS+=(foreach_noinit)
foreach_noinit() {
	$GP init
	$GP create a b c || return 1
	rm -r .gitparallel
	$GP foreach status --porcelain && return 2
	return 0
}

### Test that the command does not change the current working directory.
TESTS+=(foreach_pwd)
foreach_pwd() {
	$GP init
	$GP checkout --create master || return 1
	mkdir aaa
	cd aaa
	touch bbb
	.$GP foreach add bbb || return 2
	return 0
}

### Test the restoration of the previous environment.
TESTS+=(foreach_restore)
foreach_restore() {
	$GP init
	$GP create a b c || return 1
	$GP foreach status --porcelain || return 2
	[[ -e .git ]] && return 3
	mkdir .git
	touch .git/foobar
	$GP foreach status --porcelain || return 4
	$GP foreach status --porcelain || return 5
	[[ -e .git/foobar ]] || return 6
	return 0
}

### Test the non-expansion of arguments.
TESTS+=(foreach_eval)
foreach_eval() {
	$GP init
	$GP create a b c || return 1
	$GP foreach status --porcelain '(' || return 2
	return 0
}

## == Tests for the `upgrade` subcommand ==
### Test the output, when an upgrade from version <2.0.0 is needed.
TESTS+=(upgrade_sub_v2_0_0)
upgrade_sub_v2_0_0() {
	mkdir .gitparallel
	mkdir .gitparallel/{a,b,c}
	ln -s .gitparallel/a .git
	$GP upgrade || return 1
	$GP foreach status --porcelain || return 6
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
	$GP upgrade || return 1
	$GP foreach status --porcelain && return 6
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
	$GP upgrade && return 1
	$GP foreach status --porcelain && return 6
	[[ `gp list --active` = a ]] && return 7
	return 0
}

# == The main routine ==

main() {
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
}


printf 'Running a verbose suite ...\n'
GP="./gp" main
printf 'Running a quiet suite ...\n'
GP="./gp --quiet" main
printf '\033[1m\033[32mAll passed!\033[m\n'
