FROM casperdcl/conjuring:base as core
LABEL com.jupyter.source="https://hub.docker.com/r/jupyterhub/jupyterhub/dockerfile"
# modified version of above on this date
LABEL com.jupyter.date="2019-07-01"
LABEL org.jupyter.service="jupyterhub"

RUN apt-get -yqq update && apt-get -yqq upgrade && apt-get -yqq install \
  wget git bzip2 \
  && apt-get purge && apt-get clean && rm -rf /var/lib/apt/lists/*

# install Python + NodeJS with conda
RUN wget -q https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O /tmp/miniconda.sh \
  && echo 'e1045ee415162f944b6aebfe560b8fee */tmp/miniconda.sh' | md5sum -c - \
  && bash /tmp/miniconda.sh -f -b -p /opt/conda \
  && rm /tmp/miniconda.sh \
  && /opt/conda/bin/conda update --all -y -c conda-forge \
  && /opt/conda/bin/conda install -y -c conda-forge \
    sqlalchemy tornado jinja2 traitlets requests pip pycurl nodejs configurable-http-proxy \
  && /opt/conda/bin/pip install -U pip \
  && /opt/conda/bin/conda install -y -c conda-forge notebook jupyterlab \
  && /opt/conda/bin/conda clean -a -y
ENV PATH=/opt/conda/bin:$PATH

RUN pip install --no-cache-dir -U jupyterhub

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/
EXPOSE 8000
CMD ["jupyterhub"]

## first half (rarely changing core) complete ##
## ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ##
## second half (user customisable build) ##

FROM core as conjuring

COPY custom/apt.txt .
RUN apt-get -yqq update && (cat apt.txt | xargs apt-get -yqq install) \
  && apt-get purge && apt-get clean && rm -rf /var/lib/apt/lists/* apt.txt

COPY src/env2conda.sh custom/environment*.yml ./
RUN ./env2conda.sh /opt/conda environment*.yml && conda clean -a -y && rm env2conda.sh environment*.yml

COPY custom/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && rm requirements.txt

# list of users
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} conjuring
RUN useradd -D -s /bin/bash -N
COPY src/csv2useradd.sh .
COPY custom/users.csv .
COPY custom/home_default ./home_default
RUN bash csv2useradd.sh users.csv ./home_default && rm -r users.csv home_default
RUN mv /home /opt/home-init

# jupyterhub config
COPY custom/srv/* /srv/jupyterhub/
#RUN jupyterhub --generate-certs  # internal_ssl unnecessary

ENV DEBIAN_FRONTEND ''
COPY src/entrypoint.sh /bin/
CMD ["/bin/entrypoint.sh"]
