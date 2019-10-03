# Git Parallel
[![release](https://img.shields.io/github/release/witiko/git-parallel.svg)][release]
[![CircleCI](https://circleci.com/gh/Witiko/git-parallel/tree/master.svg?style=shield)][CircleCI]

 [CircleCI]: https://circleci.com/gh/Witiko/git-parallel/tree/master "CircleCI"
 [release]:  https://github.com/Witiko/git-parallel/releases/latest  "Releases · Witiko/git-parallel"

## Introduction

With Git Parallel, several Git repositories can live inside a single directory.

[Standard Generalized Markup Language (SGML)][sgml] is a more complex precursor
to the [Extensible Markup Language (XML)][xml] commonly used nowadays. CONCUR
was a feature of SGML that enabled [parallel markup][]. Parallel markup allows
the creation of documents that share data, such as the following two documents
that capture the dramatic and metrical views of Ibsen's [Peer Gynt][]:

    <(V)line>
      <(S)speech who="Åse">Peer, you're lying!</(S)speech>
      <(S)speech who="Peer">No, I am not!</(S)speech>
    </(V)line>
    <(V)line>
      <(S)speech who="Åse">Well then, swear that it is true!</(S)speech>
    </(V)line>
    <(V)line>
      <(S)speech who="Peer">Swear? Why should I?</(S)speech>
      <(S)speech who="Åse">See, you dare not!
    </(V)line>
    <(V)line>
       It’s a lie from first to last.</(S)speech>
    </(V)line>

 [sgml]: https://en.wikipedia.org/wiki/Standard_Generalized_Markup_Language "Standard Generalized Markup Language (SGML)"
 [xml]: https://en.wikipedia.org/wiki/XML "Extensible Markup Language (XML)"
 [parallel markup]: https://en.wikipedia.org/wiki/Overlapping_markup "Overlapping markup"
 [peer gynt]: https://ebooks.adelaide.edu.au/i/ibsen/henrik/peer/ "Peer Gynt, by Henrik Ibsen"

Continuing in the same philosophy, Git Parallel is a tool that enables parallel
Git repositories. Like the dramatic and metrical view of Ibsen's play, parallel
Git repositories are also independent, but they share the same data (directory
structure):

    $ tree ~/data-repository
    /home/pgynt/data-repository/
    ├── .git
    ├── posts
    │   ├── 2019-09-16_aase-scolds-peer.md
    │   ├── 2019-09-16_peer-confronts-smith.md
    │   └── 2019-09-17_peer-meets-solveig.md
    └── resources
        ├── aase-on-the-millhouse-roof.png
        ├── peer-among-the-wedding-guests.png
        └── peer-before-the-king-of-trolls.png

    $ tree ~/code-repository
    /home/pgynt/code-repository/
    ├── Makefile
    ├── .git
    └── resources
        ├── code.js
        └── style.css

    $ gp init
    $ gp create --clone ~/data-repository master data
    $ gp create --clone ~/code-repository master code
    $ gp checkout code
    $ tree
    .
    ├── Makefile
    ├── .git
    ├── .gitparallel
    │   ├── code -> ../git
    │   └── data
    ├── posts
    │   ├── 2019-09-16_aase-scolds-peer.md
    │   ├── 2019-09-16_peer-confronts-smith.md
    │   └── 2019-09-17_peer-meets-solveig.md
    └── resources
        ├── aase-on-the-millhouse-roof.png
        ├── code.js
        ├── peer-among-the-wedding-guests.png
        ├── peer-before-the-king-of-trolls.png
        └── style.css

## Requirements

 * [Bash 4+][bash]
 * [Git][]
 * `flock` from [`util-linux`](/karelzak/util-linux) (optional)
 * `fmt` and `readlink` from [GNU Coreutils][] (optional)

 [bash]: https://www.gnu.org/software/bash/ "GNU Bash"
 [GIT]: https://git-scm.com/ "Git"
 [gnu coreutils]: http://www.gnu.org/software/coreutils/coreutils.html "Coreutils – GNU core utilities"

## Installation

 1. Copy the `gp` file into one of the directories in your `PATH` environment
    variable.

 2. To make Git-parallel accessible as a `git parallel` Git subcommand, copy
    the `git-parallel` file into one of the directories in your `PATH`
    variable.

 3. To enable Bash command completion for Git-parallel, the
    `gp.bash-completion` file needs to be sourced, when bash starts. You can do
    this at the system level by copying the `gp.bash-completion` file into the
    `/etc/bash-completion.d/` directory. You can also do this on a per-user
    basis by copying the `gp.bash-completion` file to a directory `/path/to/`,
    and then including a line such as the following in the user's `~/.bashrc`
    configuration file:

        source /path/to/gp.bash-completion
