# Git-parallel

Git-parallel, also known as `gp`, is a shell script that makes it possible to
create and switch between several Git repositories inside a single directory.
The Git repositories are stored inside a `.gitparallel` directory with
`.gitparallel/active-repo` being a symbolic link pointing to `.git`.

## Requirements

 * [Bash 4+][Bash]
 * [GIT][]
 * `flock` from [`util-linux`](/karelzak/util-linux) (optional)
 * `fmt` and `readlink` from [GNU Coreutils][] (optional)

[Bash]: https://www.gnu.org/software/bash/
[GIT]: https://git-scm.com/
[GNU Coreutils]: http://www.gnu.org/software/coreutils/coreutils.html

## Installation

 1. For barebones functionality, it is sufficient to place the file [`gp`](gp)
    into one of the directories in your `PATH` environment variable.
 2. To make Git-parallel accessible as a Git subcommand `git parallel`, place
    the file [`git-parallel`](git-parallel) into one of the directories in your
    `PATH` variable as well.
 3. To enable Bash command completion for Git-parallel, the
    [`gp.bash-completion`](gp.bash-completion) script needs to be sourced, when
    bash starts. This can be done at the system level by moving the script into
    the `/etc/bash-completion.d/` directory, or on a per-user basis by
    including a line such as

        source path/to/gp.bash-completion

    into the `~/.bashrc` configuration file.

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
	gp do repoA -- add fileA fileB fileC
	gp do repoB -- add fileC fileD fileE
	gp foreach commit -m 'initial commit.'

	# Migrates an existing Git repository to gp.
	git init
	gp create --migrate repoC

	# Switches between the gp repositories.
	gp checkout --clobber repoA
	gp checkout repoB
	gp checkout repoC

	# Removes the gp repositories.
	gp rm repoA repoB
	gp rm --force repoC
