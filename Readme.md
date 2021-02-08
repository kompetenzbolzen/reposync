# reposync

Scripts for juggling git repos

## gitwrapper.sh

An ssh gatekeeper and helper.
It is set and configured via the `command` option in `authorized_keys`.
This allows it to grant read and/or write privileges to specific folders based on SSH keys.

gitwrapper.sh automatically creates repositories if they are pushed for the first time.
If a non-existent repo is pulled, an empty one is sent instead.
This feature requires `$HOME/empty.git` to be an empty git repository.

This allows for easy creation of new repos by just cloning any name, creating a first commit,
and then pushing.

#### Options

    gitwrapper.sh OPTIONS
    -r <DIR>	Allow pull from DIR
    -w <DIR>	Allow push to DIR
    -a <DIR>	Allow push/pull from/to DIR
    -i		Allow inetractive Login

#### Example

    # .ssh/authorized_keys
    
    # Allow bob read/write on bob and read on public
    command="gitwrapper.sh -a bob -r public" ssh-rsa AAAA... bob@bobpc
    
    # Allow joe read on public
    command="gitwrapper.sh -r public" ssh-rsa AAAA... joe@joepc

## github_sync.sh

This script handles mirroring to GitHub via the GitHub API.
Note that it only ever pushes, so changes on GitHub will result in failure.
The first argument specifies the configuration file, setting the following variables:

    USERNAME	GitHub Username
    TOKEN	GitHub Authorization Token
    REPO_DIR	local repository directory
    PRIVATE	Specifies, whether $REPO_DIR should be trated as public (false) or private (true)
    		Repos will be created on GitHub accordingly
    LIMIT	Limit syncing to repos specified in LIMIT_TO (true/false)
    LIMIT_TO	Array of repos to limit syncing to

## License

MIT
