# Git-parallel

[![Circle CI](https://img.shields.io/circleci/project/Witiko/git-parallel/master.svg)](https://circleci.com/gh/Witiko/git-parallel)

Have several Git repositories live inside a single directory.

## Requirements

 * [Bash 4+](https://www.gnu.org/software/bash/)

## Examples
### Creating two empty Git-parallel repositories

	$ gp init --update-gitignore
	Created a '.gitparallel' directory in '/tmp/foobar'.
	Created a '.gitignore' file.

	$ gp create repoA repoB
	Created an empty Git-parallel repository 'repoA' in '/tmp/foobar'.
	Created an empty Git-parallel repository 'repoB' in '/tmp/foobar'.

	$ tree -a
	.
	├── .gitignore
	└── .gitparallel
		├── repoA
		└── repoB

	3 directories, 1 file

	$ gp ls | gp do init
	Switched to the Git-parallel repository 'repoA'.
	Initialized empty Git repository in /tmp/foobar/.gitparallel/repoA/
	Switched to the Git-parallel repository 'repoB'.
	Initialized empty Git repository in /tmp/foobar/.gitparallel/repoB/
	Removed the '.git' symlink from '/tmp/foobar'.

	$ gp ls | gp do add .gitignore
	Switched to the Git-parallel repository 'repoA'.
	Switched to the Git-parallel repository 'repoB'.
	Removed the '.git' symlink from '/tmp/foobar'.

	$ gp ls | gp do commit -m 'initial commit.'
	Switched to the Git-parallel repository 'repoA'.
	[master (root-commit) b55b9c6] initial commit.
	 1 file changed, 1 insertion(+)
	 create mode 100644 .gitignore
	Switched to the Git-parallel repository 'repoB'.
	[master (root-commit) b55b9c6] initial commit.
	 1 file changed, 1 insertion(+)
	 create mode 100644 .gitignore
	Removed the '.git' symlink from '/tmp/foobar'.

	$ gp checkout repoA
	Switched to the Git-parallel repository 'repoA'.

	$ ls -al
	total 52
	drwxr-xr-x   3 witiko witiko  4096 led 23 19:18 .
	drwxrwxrwt 181 root   root   36864 led 23 19:18 ..
	lrwxrwxrwx   1 witiko witiko    18 led 23 19:18 .git -> .gitparallel/repoA
	-rw-r--r--   1 witiko witiko    13 led 23 19:17 .gitignore
	drwxr-xr-x   4 witiko witiko  4096 led 23 19:17 .gitparallel

	$ git log
	commit b55b9c69dce35cc0897cbf51d262fbf21417675a
	Author: witiko <witiko@mail.muni.cz>
	Date:   Sat Jan 23 19:34:08 2016 +0100

	    initial commit.

### Migrating a Git repository to Git-parallel

	$ gp init --follow-git --update-gitignore
	Created a '.gitparallel' directory in '/tmp/foobar'.
	Updated the '.gitignore' file.

	$ gp checkout --create --migrate repoA
	Migrated '/tmp/foobar/.git' to '/tmp/foobar/.gitparallel/repoA'.
	Switched to a new Git-parallel repository 'repoA'.

	$ ls -al
	total 52
	drwxr-xr-x   3 witiko witiko  4096 led 23 19:22 .
	drwxrwxrwt 181 root   root   36864 led 23 19:22 ..
	lrwxrwxrwx   1 witiko witiko    18 led 23 19:22 .git -> .gitparallel/repoA
	-rw-r--r--   1 witiko witiko    13 led 23 19:22 .gitignore
	drwxr-xr-x   3 witiko witiko  4096 led 23 19:22 .gitparallel

### Removing a Git-parallel repository

	$ gp ls
	  repoA
	* repoB

	$ gp rm repoA
	Removed the Git-parallel repository 'repoA' from '/tmp/foobar'.

	$ ls
	total 52
	drwxr-xr-x   3 witiko witiko  4096 Jan 23 19:26 .
	drwxrwxrwt 181 root   root   36864 Jan 23 19:26 ..
	lrwxrwxrwx   1 witiko witiko    18 Jan 23 19:26 .git -> .gitparallel/repoB
	-rw-r--r--   1 witiko witiko    13 Jan 23 19:22 .gitignore
	drwxr-xr-x   3 witiko witiko  4096 Jan 23 19:26 .gitparallel

	$ gp rm repoB
	The Git-parallel repository

		repoB

	is active. By removing it, the contents of your active Git repository WILL BE
	LOST! To approve the removal, specify the -f / --force option.

	$ gp rm --force repoB
	Removed the active Git-parallel repository 'repoB' from '/tmp/foobar'.

	$ ls
	total 52
	drwxr-xr-x   3 witiko witiko  4096 Jan 23 19:27 .
	drwxrwxrwt 181 root   root   36864 Jan 23 19:27 ..
	-rw-r--r--   1 witiko witiko    13 Jan 23 19:22 .gitignore
	drwxr-xr-x   2 witiko witiko  4096 Jan 23 19:27 .gitparallel
