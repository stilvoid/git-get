# git-get

git-get is an opinionated git command that helps you keep your code folder in order.

git-get is a simple wrapper for `git clone` that clones your repository into a standard location so that you always know where your code is.

git-get will place you inside your new folder when you're done because it saves typing `cd <the thing you just typed already>` :)

## Installing

All you get to do is to put `git-get` somewhere in your path :)

## Examples

```shell
git get https://github.com/stilvoid/git-get
Cloning into '/home/steve/code/github.com/stilvoid/git-get'...
```

git-get uses the repository URL to figure out where to place your checked out copy.

By default, git-get places all repositories under `~/code` but you can change that by setting get.location:

```shell
git config --global get.location ~/projects
```
