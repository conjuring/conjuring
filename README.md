# Conjuring

*Conjuring* provides an easy way for students and teachers to use Python for a
course.

[![CI-badge]][CI]

Technically, Conjuring can be viewed as a multi-user ([`jupyterhub`]) version of
[`repo2docker`] (turn `git` repositories into *Jupyter*-enabled *Docker* Images)
without requiring Python on the host. Don't worry if that sounds unintelligible.
It's really cool. Trust us.

Specifically, Conjuring is designed with [Geocomputing at KCL in mind][geocomp];
though is general enough to be used for any course.

We assume Conjuring will run on a single machine on a private network. Students
(clients) on the same network will connect to the machine via their web browsers
to access their Python workspace. The Python web interface is called *Jupyter*.

*JupyterHub* is used to manage multiple student accounts; each with their own
isolated workspace.

JupyterHub recommends "The Littlest JupyterHub ([TLJH])" or "Zero to JupyterHub
([Z2JH])" to install, neither of which are appropriate in our case. We thus
manually install it ourselves. It would be painful to provide installation
instructions for all operating systems. Instead, we provide a docker container
(which can run on any supported OS). The container itself runs Ubuntu 18.04.

[`jupyterhub`]: https://github.com/jupyterhub/jupyterhub
[`repo2docker`]: https://github.com/jupyter/repo2docker
[geocomp]: https://www.kcl.ac.uk/sspp/departments/geography/research/Research-Domains/Geocomputation/About-Us
[TLJH]: https://tljh.jupyter.org
[Z2JH]: https://z2jh.jupyter.org

# Installation

## Prerequisites
- A machine which is accessible by students
  (e.g. via Ethernet or even a WiFi hotspot)
- [Docker CE (Community Edition)][docker-ce]
- [docker-compose][docker-compose]

[docker-ce]: https://docs.docker.com/install/
[docker-compose]: https://github.com/docker/compose/releases

## Instructions
1. Download and if necessary customise (see below)
2. Run `docker-compose up --build -d`

The Conjuring JupyterHub machine should be built and accessible via a browser on
<http://localhost:8989>.

To shut down, run `docker-compose down`.
Student home directories will persist in the [custom/home/](custom/home/)
folder with the correct access permissions.

### Customisation
Configuration files are all found within the [custom/](custom/) directory.

- Define packages to `apt install`
    + Modify [apt.txt](custom/apt.txt)
- Define packages to `conda install`
    + Modify [environment.yml](custom/environment.yml)
- Define packages to `pip install`
    + Modify [environment.yml](custom/environment.yml) or [requirements.txt](custom/requirements.txt)
- Define alternative environments (kernels)
    + Create `environment-<name>.yml` files
- Define student usernames and passwords
    + Modify [users.csv](custom/users.csv) (first row is a header and is ignored)
- Define files which should be copied to each student's workspace
    + Add files to [home_default/](custom/home_default/)
- Define read-only files which should be shared for all students
    + Add files to [shared/](custom/shared/)
- Change the base image to something other than `ubuntu:18.04`
    + Modify [base.Dockerfile](custom/base.Dockerfile)

### Auto-boot
A physical server can be configured to automatically start conjuring upon
bootup, start a hotspot (or connect to a network),
and monitor for external USB drives with additional configuration.

- Use the [autoboot.sh](autoboot.sh) script for this purpose
    + Run `crontab -e` and add `@reboot cd /path/to/conjuring && ./autoboot.sh`
    + Run `sudo apt-get install git openssh-server make sudo`
    + Run `sudo visudo` and add the line `%sudo ALL=(ALL) NOPASSWD:ALL`
    + Enable `Settings` > `Details` > `Users` > `Automatic Login`

Notes:

- The path monitored for a configuration folder is `/media/*/*/conjuring/custom`
- The default network which is connected to is called `Hotspot`
    + This can be set up in `Settings` > `Wi-Fi` > `(settings icon)` >
      `Turn On Wi-Fi Hotspot...`,
      then running (in a terminal) `nm-connection-editor` to rename the
      connection to `Hotspot` and edit the password
    + Alternatively, choose a different default (e.g. external) network name by
      modifying `autoboot.sh`
    + The NUC itself and all clients need to be on the same network. This means
      that the NUC doesn't have to act as a Wi-Fi hotspot if there's a
      pre-existing Wi-Fi network which everyone can connect to

# FAQ

## How does it all work?

If you are not familiar with docker, it may seem quite complicated.
This overview (combined with the [glossary](#glossary) below) might help.

`docker-compose` reads [docker-compose.yml](docker-compose.yml) (and if it
exits, `docker-compose.override.yml`) in order to make the following happen:

1. `docker` downloads the latest version of the `ubuntu:18.04` *image*
2. `docker` follows the instructions in
   [custom/base.Dockerfile](custom/base.Dockerfile) to (re)build
   an *image* called `conjuring/conjuring:base` (based on `ubuntu:18.04`)
3. `docker` follows the instructions in the first half of
   [Dockerfile](Dockerfile) to (re)build an *image* called
   `conjuring/conjuring:core` (based on `conjuring/conjuring:base`)
4. `docker` follows the instructions in the second half of
   [Dockerfile](Dockerfile) to (re)build an *image* called
   `conjuring/conjuring:latest` (based on `conjuring/conjuring:core`)
    - this references files from the [src/](src/) and [custom/](custom/)
      directories to create users and Jupyter environments
5. `docker` creates a *container* called `conjuring`
   (based on `conjuring/conjuring:latest`) which also does the following:
    - links [custom/home/](custom/home/) to `conjuring:/home/`
    - links [custom/home_default/](custom/home_default) (read-only)
    - populates the container user home directories (`conjuring:/home/*`)
        * links [custom/shared/](custom/shared) (read-only)
    - starts a `JupyterHub` server accessible on the host at
      <http://localhost:8989>

All builds are "cached", i.e. unchanged lines from `*Dockerfile` will be not
actually be re-run; saving time and bandwidth. Note that a line which references
a changed file (from [src/](src/) or [custom/](custom/)) also counts as a
changed line.

Run `docker system prune` to clear unused cache.

# Glossary

- *Base image*: the starting point for building a Docker *image*
    + analogous to a clean OS (in this case `ubuntu:18.04`)
- *Layer*: a single (cached) build step
    + usually represented by a single line in a `Dockerfile`
      (e.g. `apt-get install git`)
- *Image*: a sequence of *layers* (applied on top of a *base image*)
    + analogous to a clean OS with things set up as specified in `custom/`
      (in this case *tagged* `conjuring/conjuring:latest`)
- *Container*: a sandboxed workspace derived from an *image*
    + analogous to a running virtual machine (in this case named `conjuring`)
    + easily stoppable, restartable, and disposable
    + can be thought of as end-user-created *layers* which would never be
      formally part of a redistributable *image*
    + can share files, network connections, and devices with the host computer

*Images* are *pulled* or *built*. *Containers* are *created* from them:

- *Pull*: typically refers to downloading an *image* from the internet (which someone else *built*)
    + usually only required when there is no source code available to allow for *building* locally (e.g. `ubuntu:18.04`)
- *Build*: typically refers to *pulling* a *base image*, then *building* all the *layers* necessary to form an *image*
    + usually once-off
- *Create*: typically refers to making a *container* from an *image*
    + often recreated for a semi-clean slate - especially if data is shared with the host computer so that no data is lost on disposal

## Software

- *Python*: a programming language designed to be very human-readable

- *Jupyter*: an IDE (integrated development environment -- i.e. glorified text
editor) which runs in a web browser

- *JupyterHub*: a tool to manage multiple Jupyter servers for multiple users

- *git*: a code version control tool

- *Docker*: a virtual machine replacement tool
    + allows running e.g. isolated Ubuntu Linux JupyterHub containers on any host operating system

## Websites

- *GitHub*: a website which hosts many *git* repositories

[CI-badge]: https://img.shields.io/github/workflow/status/conjuring/conjuring/Test/master?logo=GitHub
[CI]: https://github.com/conjuring/conjuring/actions/workflows/test.yml
