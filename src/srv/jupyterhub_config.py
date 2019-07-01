# self-signed keys would create an alert in most browsers.
# perhaps better to disable SSL over
c.JupyterHub.ssl_key = '/srv/jupyterhub/my.key'
c.JupyterHub.ssl_cert = '/srv/jupyterhub/my.cert'

# unnecessary
#c.JupyterHub.internal_ssl = True
