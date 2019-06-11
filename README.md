# Conjuring

*Conjuring* provides an easy way for students and teachers to use Python for a
course.

Specifically, Conjuring is designed with [Geocomputing at KCL in mind][geocomp];
though is general enough to be used for any course.

We assume Conjuring will run on a single machine on a private network. Students
(clients) on the same network will connect to the machine via their web browsers
to access their Python workspace. The Python web interface is called *Jupyter*.

*JupyterHub* is used to manage multiple student accounts; each with their own
isolated workspace.

JupyterHub recommends "The Littlest JupyterHub (TLJH)" or "Zero to JupyterHub
(Z2JH)" to install, neither of which are appropriate in our case. We thus
manually install it ourselves. It would be painful to provide installation
instructions for all operating systems. Instead, we provide a docker container
(which can run on any supported OS). The container itself runs Ubuntu 18.04.

[geocomp]: TODO

# Installation

## Prerequisites
- A machine which is accessible by students (e.g. via Ethernet or even a WiFi hotspot)
- [Docker CE (Community Edition)][docker-ce]
- [docker-compose][docker-compose]

[docker-ce]: https://docs.docker.com/install/
[docker-compose]: https://github.com/docker/compose/releases

## Instructions
1. Download and if necessary customise (see below)
2. Run `docker-compose up -d`

The Conjuring JupyterHub machine should be built and accessible via a browser on
<https://localhost:8989>. You may have to add a security exception in your
browser (Conjuring's SSL certificate is self-signed).

To shut down, run `docker-compose down`.
TODO: Student home directories will persist.

### Customisation
Configuration files are all found within the `custom` directory.

- Define student usernames and passwords
  + Modify `users.csv`
- Define files which should be copied to each student's workspace
  + Add files to `home_default`
- Define packages to `apt install`
  + Modify `apt.txt`
- Define packages to `conda install`
  + Modify `requirements-conda.txt`
- Define packages to `pip install`
  + Modify `requirements-pip.txt`

# Glossary

## Software

Python
: A programming language designed to be very human-readable.

Jupyter
: An IDE (integrated development environment -- i.e. glorified text editor) which
runs in a web browser.

JupyterHub
: A tool to manage multiple Jupyter servers for multiple users.

git
: A code version control tool

Docker
: A virtual machine replacement tool. Allows running e.g. isolated Ubuntu Linux JupyterHub containers on any host operating system.

## Websites

GitHub
: A website which hosts many git repositories
