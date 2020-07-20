# reposync

Script for juggling git repos

## gitwrapper.sh

gitwrapper.sh automatically creates repositories if they are pushed for the first time.
If a non-existent repo is pulled, an empty one is sent instead.

This allows for easy creation of new repos by just cloning any name, creating a first commit,
and then pushing.git@git:jonas/toybox.git

`gitwrapper.sh OPTIONS` is set as a command in `.ssh/authorized_keys`

#### Options

    gitwrapper.sh OPTIONS
    -r <DIR>	Allow pull from DIR
    -w <DIR>	Allow push to DIR
    -a <DIR>	Allow push/pull from/to DIR
    -i		Allow inetractive Login

## reposync.sh

This script handles synchronisation to GitHub via the GitHub API and SSH,
so it needs a valid API key and an authorized SSH key.
`~/settings.sh` provides `$USERNAME`, `$TOKEN` and `$REPO_DIR`.
If a repo only exists locally, it is created via the API, then pushed.
All repos present on both sides are pushed.
All remote-only repos are cloned.
The last behaviour is only intended for migrating, not for usage.
Repos are only pushed, never fetched so GitHub acts as a mirror and thus should be treated as read-only.

## License

MIT
