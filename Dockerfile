FROM jupyterhub/jupyterhub:latest as core
RUN conda update --all -y && conda install notebook jupyterlab -y

FROM core as conjuring

# list of users
RUN groupadd conjuring
RUN useradd -D -s /bin/bash -N
RUN useradd -r -G conjuring -m -p $(echo "duper" | openssl passwd -1 -stdin) super
