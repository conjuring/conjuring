# Conjuring

[![CI-badge]][CI]

*Conjuring* provides an easy way for students and teachers to use Python for a
course.

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

[geocomp]: TODO
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
bootup, and monitor for external USB drives with additional configuration.

Use the [autoboot.sh](autoboot.sh) script for this purpose.
The path monitored for a configuration folder is `/media/*/*/conjuring/custom`.

TODO: `cron`, sync policy.

# FAQ

## How does it all work?

If you are not familiar with docker, it may seem quite complicated.
This overview (combined with the [glossary](#glossary) below) might help.

`docker-compose` reads [docker-compose.yml](docker-compose.yml) (and if it
exits, `docker-compose.override.yml`) in order to make the following happen:

1. `docker` downloads the latest version of the `ubuntu:18.04` *image*
2. `docker` follows the instructions in
   [custom/base.Dockerfile](custom/base.Dockerfile) to (re)build
   an *image* called `casperdcl/conjuring:base` (based on `ubuntu:18.04`)
3. `docker` follows the instructions in the first half of
   [Dockerfile](Dockerfile) to (re)build an *image* called
   `casperdcl/conjuring:core` (based on `casperdcl/conjuring:base`)
4. `docker` follows the instructions in the second half of
   [Dockerfile](Dockerfile) to (re)build an *image* called
   `casperdcl/conjuring:latest` (based on `casperdcl/conjuring:core`)
    - this references files from the [src/](src/) and [custom/](custom/)
      directories to create users and Jupyter environments
5. `docker` creates a *container* called `conjuring`
   (based on `casperdcl/conjuring:latest`) which also does the following:
    - links [custom/home/](custom/home/) to `conjuring:/home/`
    - populates the container user home directories (`conjuring:/home/*`)
        * links [custom/shared/](custom/shared)
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
      (in this case *tagged* `casperdcl/conjuring:latest`)
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

[CI-badge]: https://travis-ci.com/casperdcl/conjuring.svg?token=fZcPAkurhLa1iecqAFAV&branch=master
[CI]: https://travis-ci.com/casperdcl/conjuring
