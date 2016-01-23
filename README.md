# Git-parallel

[![Circle CI](https://img.shields.io/circleci/project/Witiko/git-parallel/master.svg)](https://circleci.com/gh/Witiko/git-parallel)

Have several Git repositories living inside a single directory.

## Requirements

 * [Git](http://git-scm.com/)
 * [Bash 4+](https://www.gnu.org/software/bash/)

## Examples
### Creating two empty Git-parallel repositories

	$ gp init foo bar
	Initialized an empty Git-parallel repository in `.gitparallel/foo`.
	Initialized an empty Git-parallel repository in `.gitparallel/bar`.

	$ tree -a
	.
	├── .gitignore
	└── .gitparallel
	    ├── foo
	    └── bar

	3 directories, 1 file

	$ gp ls | gp do init
	Switched to the Git-parallel repository `foo`.
	Initialized empty Git repository in /tmp/xyz/.gitparallel/foo/
	Switched to the Git-parallel repository `bar`.
	Initialized empty Git repository in /tmp/xyz/.gitparallel/bar/
	Restored the original state of the `.git` directory.

	$ gp ls | gp do add .gitignore
	Switched to the Git-parallel repository `foo`.
	Switched to the Git-parallel repository `bar`.
	Restored the original state of the `.git` directory.

	$ gp ls | gp do commit -m 'initial commit.'
	Switched to the Git-parallel repository `foo`.
	[master (root-commit) 00b120f] initial commit.
	 1 file changed, 1 insertion(+)
	 create mode 100644 .gitignore
	Switched to the Git-parallel repository `bar`.
	[master (root-commit) 00b120f] initial commit.
	 1 file changed, 1 insertion(+)
	 create mode 100644 .gitignore
	Restored the original state of the `.git` directory.

	$ gp checkout foo
	Switched to the Git-parallel repository `foo`.

	$ ls -al
	total 52
	drwxr-xr-x  3 witiko witiko  4096 Jan 23 06:50 .
	drwxrwxrwt 70 root   root   36864 Jan 23 06:50 ..
	lrwxrwxrwx  1 witiko witiko    21 Jan 23 06:50 .git -> .gitparallel/foo
	-rw-r--r--  1 witiko witiko    13 Jan 23 06:47 .gitignore
	drwxr-xr-x  4 witiko witiko  4096 Jan 23 06:47 .gitparallel

### Migrating a Git repository to Git-parallel

	$ git init
	Initialized empty Git repository in /tmp/foobar/.git/

	$ gp checkout --init --migrate foo
	Migrated the active Git repository to `.gitparallel/foo`.
	Switched to a new Git-parallel repository `foo`.

	$ ls -al
	total 52
	drwxr-xr-x  3 witiko witiko  4096 Jan 23 06:50 .
	drwxrwxrwt 70 root   root   36864 Jan 23 06:50 ..
	lrwxrwxrwx  1 witiko witiko    21 Jan 23 06:50 .git -> .gitparallel/foo
	-rw-r--r--  1 witiko witiko    13 Jan 23 06:47 .gitignore
	drwxr-xr-x  4 witiko witiko  4096 Jan 23 06:47 .gitparallel

	$ gp rm foo
	The Git-parallel repository

		foo

	is active. By removing it, the contents of your active Git repository WILL BE
	LOST! To approve the removal, specify the -f / --force option.

	$ gp rm --force foo
	Removed the active Git-parallel repository `foo`.