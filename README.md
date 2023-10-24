# devcontainers

Several different [devcontainers](https://code.visualstudio.com/docs/devcontainers/containers) for vscode

#### Security note

**There is no security**. None, literally. The container impersonates you, its creator, to allow for
seamless sharing of workspace files inside and outside of container. If someone runs your container,
they might gain access to your SSH keys (assuming you are logged in) and will definitely gain access
to your workspace files. It is specifically designed this way to allow for `git` and vscode extensions
to work inside the container. You should only use this on a computer that is not shared with anyone.

**This pulls .zshrc from grml** into the container, because I like to use it. You might want to remove it.

Perhaps there is a way to convince devcontainers extension to use `docker run --user` option, but I
did not go this far reading documentation. This would remove the "impersonation" problem.
_Let me know if you find it._


#### Instructions:
- Add `export GID; export UID` to your `~/.profile`; these are used by vscode to impersonate you when building your container
  - you know what to do after a change to `~/.profile`
- Make your own fork of this repo, so you can modify it to your heart's content
- Add "Dev Containers" extension from Microsoft to your vscode
- Clone the whole repo inside `.devcontainer` (note singular, no "s") folder in your project
- Add `/.devcontainer/` folder to either of `.gitignore` or `.git/info/exclude` (or perhaps use submodules ?)
- In the bottom left corner of vscode find icon that looks a little like `><`
- Click on it, then find at the top of vscode a selection of options for Remote Window
- Select "Reopen in Container" option
- Select desired container type from the list
  - clang-17 is not yet supported by conan
  - fedora containers do not support clang-format-11
  - building the container first time will take some time
- Inside the container, do `cat ~/TODO.txt` and carry on from there


#### Troubleshooting

Read https://code.visualstudio.com/docs/devcontainers/containers and https://containers.dev/

**Some things and assumptions which work for me, might not work for you.**
