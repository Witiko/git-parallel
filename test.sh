#!/bin/bash
# == Test definitions ==
TESTS=()

## == Tests for the `init` subcommand ==
### Test the basic functionality of the command.
TESTS+=(init)
init() {
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	./gp init a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	./gp init a b c && return 4
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 5
	./gp init d e f || return 6
	[[ "`ls .gitparallel | wc -l`" = 6 ]] || return 7
}

### Test the correct handling of --.
TESTS+=(init_dbldash)
init_dbldash() {
	./gp init a b c -- -m --migrate -c --clobber || return 1
	[[ "`ls .gitparallel | wc -l`" = 7 ]] || return 2
	return 0
}

### Test the correct handling of empty input.
TESTS+=(init_empty)
init_empty() {
	./gp init && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(init_alias)
init_alias() {
	./gp i a b c
}

### Test the correct handling of the -m / --migrate option.
TESTS+=(init_migrate)
init_migrate() {
	./gp init -m a b c && return 1
	./gp init --migrate a b c && return 2
	mkdir .git
	touch .git/foobar
	./gp init -m a b c || return 3
	[[ -e .gitparallel/a/foobar ]] || return 4
	[[ -e .gitparallel/b/foobar ]] || return 5
	[[ -e .gitparallel/c/foobar ]] || return 6
	./gp init --migrate a b c && return 7
	./gp init --migrate d e f || return 8
	[[ -e .gitparallel/d/foobar ]] || return 9
	[[ -e .gitparallel/e/foobar ]] || return 10
	[[ -e .gitparallel/f/foobar ]] || return 11
	./gp init -m d e f && return 12
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(init_checkNames)
init_checkNames() {
	./gp init a b c '' && return 1
	./gp init a b/c d && return 2
	./gp init . b c d && return 3
	return 0
}

## == Tests for the `remove` subcommand ==
### Test the basic functionality of the command.
TESTS+=(remove)
remove() {
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 1
	./gp init a b c || return 2
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 3
	./gp init d e f || return 4
	[[ "`ls .gitparallel | wc -l`" = 6 ]] || return 5
	./gp remove a c e || return 6
	[[ "`ls .gitparallel | wc -l`" = 3 ]] || return 7
	./gp remove b d f || return 8
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 9
	return 0
}

### Test the correct handling of --.
TESTS+=(remove_dbldash)
remove_dbldash() {
	./gp init a b c -- -f --force || return 1
	[[ "`ls .gitparallel | wc -l`" = 5 ]] || return 2
	./gp remove a b c -- -f --force || return 3
	[[ "`ls .gitparallel | wc -l`" = 0 ]] || return 4
	return 0
}

### Test the correct handling of empty input.
TESTS+=(remove_empty)
remove_empty() {
	./gp remove && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(remove_alias)
remove_alias() {
	./gp rm a && return 1
	./gp init a || return 2
	./gp rm a || return 3
	return 0
}

### Test the correct handling of the -f / --force option.
TESTS+=(remove_force)
remove_force() {
	./gp init a b || return 1
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
	./gp remove '' && return 1
	return 0
}

## == Tests for the `list` subcommand ==
### Test the basic functionality of the command.
TESTS+=(list)
list() {
	[[ "`./gp list | wc -l`" = 0 ]] || return 1
	./gp init a b c || return 2
	[[ "`./gp list | wc -l`" = 3 ]] || return 3
	./gp init d e f || return 4
	[[ "`./gp list | wc -l`" = 6 ]] || return 5
	./gp remove a c e || return 6
	[[ "`./gp list | wc -l`" = 3 ]] || return 7
	./gp remove b d f || return 8
	[[ "`./gp list | wc -l`" = 0 ]] || return 9
	return 0
}

### Test the correct handling of bogus input.
TESTS+=(list_bogus)
list_bogus() {
	./gp nonsense && return 1
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(list_alias)
list_alias() {
	./gp ls
}

### Test the correct handling of the -p / --porcelain and -H / --human-readable
### options.
TESTS+=(list_porcelain)
list_porcelain() {
	./gp init a b c || return 1
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
	./gp checkout a && return 1
	./gp init a || return 2
	./gp checkout a || return 3
	./gp remove --force a || return 4
	./gp checkout a && return 5
	return 0
}

### Test the correct handling of the -c / --clobber option.
TESTS+=(checkout_clobber)
checkout_clobber() {
	./gp init a b || return 1
	./gp checkout a || return 2
	./gp checkout b || return 3
	rm .git
	mkdir .git
	./gp checkout a && return 4
	./gp checkout --clobber a || return 5
	rm .git
	mkdir .git
	./gp checkout b && return 6
	./gp checkout -c b || return 7
	return 0
}

### Test the correct handling of the -i / --init option.
TESTS+=(checkout_init)
checkout_init() {
	./gp checkout a && return 1
	./gp checkout --init a || return 2
	./gp checkout b && return 3
	./gp checkout -i b || return 4
	[[ "`./gp list | wc -l`" = 2 ]] || return 5
	return 0
}

### Test the correct handling of empty input.
TESTS+=(checkout_empty)
checkout_empty() {
	./gp checkout --init && return 1
	return 0
}

### Test the correct handling of extraneous input.
TESTS+=(checkout_extra)
checkout_extra() {
	./gp checkout --init foo bar && return 1
	return 0
}

### Test the correct handling of --.
TESTS+=(checkout_dbldash)
checkout_dbldash() {
	./gp init a b c -- -i --init -m --migrate -c --clobber || return 1
	./gp checkout -- -i || return 2
	./gp checkout -- --init || return 3
	./gp checkout -- -m || return 4
	./gp checkout -- --migrate || return 5
	./gp checkout -- -c || return 6
	./gp checkout -- --clobber || return 7
	return 0
}

### Test the correct handling of the command alias.
TESTS+=(checkout_alias)
checkout_alias() {
	./gp co a && return 1
	./gp init a || return 2
	./gp co a || return 3
	./gp rm --force a || return 4
	./gp co a && return 5
	return 0
}

### Test the correct handling of the -m / --migrate option.
TESTS+=(checkout_migrate)
checkout_migrate() {
	./gp checkout --init -m a && return 1
	./gp checkout --init --migrate a && return 2
	mkdir .git
	touch .git/foobar
	./gp checkout --init -m a || return 3
	[[ -e .gitparallel/a/foobar ]] || return 4
	./gp checkout --init --migrate a && return 5
	rm .git || return 6
	mkdir .git
	touch .git/foobar
	./gp checkout --init --migrate b || return 7
	[[ -e .gitparallel/b/foobar ]] || return 8
	./gp checkout --init -m b && return 9
	return 0
}

### Test the correct handling of illegal project names.
TESTS+=(checkout_checkNames)
checkout_checkNames() {
	./gp checkout --init '' && return 1
	./gp checkout --init a/b && return 2
	./gp checkout --init . && return 3
	return 0
}

## == Tests for the `do` subcommand ==
### Test the basic functionality of the command.
TESTS+=(do_cmd)
do_cmd() {
	./gp init a b c || return 1
	./gp list | ./gp do status --porcelain && return 2
	./gp list | ./gp do init || return 3
	./gp list | ./gp do status --porcelain || return 4
	return 0
}

### Test the restoration of the previous environment.
TESTS+=(do_restore)
do_restore() {
	./gp init a b c || return 1
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

# == The main routine ==
for TEST in "${TESTS[@]}"; do
	printf 'Running \033[1m%s\033[m ...' "$TEST"
	DIR="`mktemp -d`" &&
	{ if (cp gp "$DIR"/gp && cd "$DIR" && "$TEST" &>/dev/null); then
		printf '\t\033[1m\033[32m[OK]\033[m\n'
	else
		printf '\t\033[1m\033[31m[FAILED: %d]\033[m\n' "$?"
		exit 1
	fi
	rm -rf "$DIR"; }
done
printf '\033[1m\033[32mAll passed!\033[m\n'
