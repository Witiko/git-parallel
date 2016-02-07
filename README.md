# Git-parallel

[![Circle CI](https://img.shields.io/circleci/project/Witiko/git-parallel/master.svg)](https://circleci.com/gh/Witiko/git-parallel)

Git-parallel, also known as `gp`, is a shell script that makes it possible to
create and switch between several Git repositories inside a single directory.
The Git repositories are stored inside a `.gitparallel` directory with `.git`
being a symbolic link pointing to `.gitparallel/active-repo`.

## Requirements

 * [Bash 4+](https://www.gnu.org/software/bash/)

## How does `gp` relate to Git submodules?

They are unrelated:

* Git submodules are Git repositories inside a Git superrepository. Their
	origin is known to the superrepository, although their content is not stored
	in it. They enable easy sharing of composite repositories. Git submodules
	each have their designated directory; they can not be mixed.
* `gp` creates collections of Git repositories inside a single directory. These
	repositories are not in a superrepository-subrepository relationship; in
	fact, they are completely unaware of one another. Git-parallel collections
	exist only on your local machine; Git does not see them, so you can not push
	them to a remote, only the individual repos they contain.

## How does `gp` relate to Git branches?

With regards to what you can do with them, the two are very similar, although
not completely equivalent (branches cannot have separate hooks, config, etc.
whereas repositories can). The main difference is in the semantics. Suppose you
have several files from different projects inside a single directory.  To track
these files, you _could_ create one Git repository with separate branches, but
in fact, these files are unrelated and belong to separate repositories.

Using branches instead of repositories also makes it unpractical to work on
several of these projects at once. That is because unlike repositories,
branches do not have separate index files, so you need to stash your staged
changes when switching and restore them afterwards:

	git stash
	git checkout other-branch
	git commit -am 'updated several files.'
	git checkout previous-branch
	git stash pop

Suppose you would now like to share some of the files between the projects.
This adds more complexity to the workflow:

	# This works only when you've commited the shared files in previous-branch,
	# otherwise they will be stashed.
	git stash
	git checkout other-branch
	git checkout previous-branch shared-file1 shared-file2 ... shared-fileN
	git commit -am 'updated several files.'
	git checkout previous-branch
	git stash pop

	# This always works, but you lose your staged changes in previous-branch.
	git symbolic-ref HEAD refs/heads/other-branch
	git reset --mixed other-branch
	git commit -am 'updated several files.'
	git symbolic-ref HEAD refs/heads/previous-branch
	git reset --mixed previous-branch

I do not believe this is sane. Compare this to commiting changes to a `gp`
repository:

	gp do other-repo -- commit -am 'updated several files.'

## How do I use `gp`?
The `gp help` command should have you covered. Here are some examples of the
basic usage of `gp`:

	# Creates two empty gp repositories.
	gp init
	gp create repoA repoB
	gp foreach init
	gp foreach commit -m 'initial commit.'

	# Migrates an existing Git repository to gp.
	gp create --migrate repoC

	# Switches between the gp repositories.
	gp checkout --clobber repoA
	gp checkout repoB
	gp checkout repoC

	# Removes the gp repositories.
	gp rm repoA repoB
	gp rm --force repoC
