# reposync

Script for juggling git repos

## gitwrapper.sh

Its main purpose is to create a new empty repo if a push to a non-existent one is requested.
It is intended to be used with `command=` option in `.ssh/authorized_keys`.
As a side effect, it also implements a crude access control via SSH keys.
The first argument is the folder this specific key is allowed to push to.

If the command invoked by the ssh client is not `git upload-pack`, it is executed without further checking,
if none is supplied bash starts in interactive mode.
This would allow anyone to easily override the push restrictions,
so they should be seen as a fuck-up-preventer, not a security measure.

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
