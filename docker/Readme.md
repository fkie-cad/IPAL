## Gettings started

### Prerequisites

- `git`
- `docker`

#### Windows users

Install [git for Windows](https://git-scm.com/download/win).

Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
If your account has no admin privileges, [add your user to the docker-users group](https://docs.docker.com/desktop/install/windows-install/#install-docker-desktop-on-windows).

Start Docker Desktop and make sure the Docker Engine is running. You may need to start Docker Desktop with admin privileges.

Use `Git Bash` to run commands.

### Installation

Clone this repository and navigate to it.
```bash
git clone https://github.com/fkie-cad/ipal
cd docker
```

Run the following commands to deploy a docker container . All of the IPAl tools([ipal-ids](https://github.com/fkie-cad/ipal_ids_framework), [ipal-transciber](https://github.com/fkie-cad/ipal_transcriber), [ipal-evaluate](https://github.com/fkie-cad/ipal_evaluate)) will be installed and mounted inside the container.

```bash
chmod +x deploy_ipal.sh
./deploy_ipal.sh
```
If you are not sure, press <kbd>Enter</kbd> to select the default option/repository.
To change a default option, e.g. to your own fork, take a look inside the script.

Installation may take several minutes.

## Usage

### Development
For each tool, a directory will be created on the host at `./docker_installation/*` and mounted inside the container at `/home/ipal/*`.
Files can be edited inside the container and on the host. Changes take effect when you run a new command, i.e. no new installation is needed.
Watch out for file permissions!

### Container
To access your existing container, run the deployment script again.
```bash
./deploy_ipal.sh
```

If you need to install something inside the container, run
```bash
docker start ipal
docker exec -it --user root ipal /bin/bash
```
on the host. Though, you cannot use ipal as root.

### Notes
By default, many ipal tools show plots interactively. Inside the docker container, this will fail. However, there should be an option to store plots instead.
