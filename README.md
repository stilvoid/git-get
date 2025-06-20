# git-get

git-get is an opinionated git command that helps you keep your code folder in order.

git-get is a simple wrapper for `git clone` that clones your repository into a standard location so that you always know where your code is.

## Installing

Just put `git-get` somewhere in your path :)

## Usage

```
git get [--print-path] [--location <dir>] <repository> [<args>]
```

### Arguments

- `<repository>` - The repository URL to clone (required)
- `[<args>]` - Additional arguments passed directly to `git clone`

### Options

- `--print-path` - Print the full path where the repository would be cloned and exit without cloning
- `--location <dir>` - Override the base directory for this clone only
- `-h, --help` - Show help message and exit

## Examples

### Basic Usage

```shell
git get https://github.com/stilvoid/git-get
Cloning into '/home/bob/code/github.com/stilvoid/git-get'...
Successfully cloned to: /home/bob/code/github.com/stilvoid/git-get
```

git-get uses the repository URL to figure out where to place your checked out copy.

### Supported URL Formats

git-get works with various repository URL formats:

```shell
# HTTPS URLs
git get https://github.com/stilvoid/git-get.git
# → ~/code/github.com/stilvoid/git-get

# SSH URLs
git get git@github.com:stilvoid/git-get.git
# → ~/code/github.com/stilvoid/git-get

# Git protocol URLs
git get git://github.com/stilvoid/git-get.git
# → ~/code/github.com/stilvoid/git-get
```

### Configuration

By default, git-get places all repositories under `~/code` but you can change that by setting get.location:

```shell
git config --global get.location ~/projects
```

### Additional Examples

```shell
# See where a repository would be cloned without actually cloning
git get --print-path https://github.com/stilvoid/git-get

# Override the base directory for one clone only
git get --location ~/temp https://github.com/stilvoid/git-get
# → ~/temp/github.com/stilvoid/git-get

# Preview where a repository would be cloned with a custom location
git get --location ~/projects --print-path git@github.com:user/repo.git
# → ~/projects/github.com/user/repo

# Show help and usage information
git get --help

# Pass additional arguments to git clone (shallow clone)
git get --depth 1 https://github.com/stilvoid/git-get

# Clone a specific branch
git get --branch main https://github.com/stilvoid/git-get
```
