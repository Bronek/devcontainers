# devcontainers

Single [devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) for vscode

#### Security note

**There is no security**. None, literally. This container is best used in a `docker` configured
to [rootless mode](https://docs.docker.com/engine/security/rootless/). Otherwise you will be exposing
your secrets to anyone who might run this container on the same machine.

**This pulls .zshrc from grml** into the container, because I like to use it. You might want to remove it.


#### Instructions:
- Make your own fork of this repo, so you can modify it to your heart's content
- Add "Dev Containers" extension from Microsoft to your vscode
- Clone the whole repo inside `.devcontainer` (note singular, no "s") folder in your project
- Add `/.devcontainer/` folder to either of `.gitignore` or `.git/info/exclude` (or perhaps use submodules ?)
- In the bottom left corner of vscode find icon that looks a little like `><`
- Click on it, then find at the top of vscode a selection of options for Remote Window
- Select "Reopen in Container" option
- Inside the container, do `cat ~/TODO.txt` and carry on from there


#### Troubleshooting

Read https://code.visualstudio.com/docs/devcontainers/containers and https://containers.dev/

**Some things and assumptions which work for me, might not work for you.**
