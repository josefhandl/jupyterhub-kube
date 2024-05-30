#!/bin/bash

jupyterhub --generate-config

# Generate kube config file
mkdir -p ~/.kube/
tee ~/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- name: "kuba"
  cluster:
    server: "${K8SAPI_URL}"
users:
- name: "kuba-rancher-user"
  user:
    token: "${K8SAPI_TOKEN}"
contexts:
- name: "kuba"
  context:
    user: "kuba-rancher-user"
    cluster: "kuba"
    namespace: ${NAMESPACE}
current-context: "kuba"
EOF

# Get hub's namespace label and annotation to include new namespaces into the same Rancher's project
PROJECTID_ANNOTATION=$(/srv/jupyterhub/kubectl get namespace "${NAMESPACE}" -o custom-columns="${NAMESPACE}:metadata.annotations.field\.cattle\.io\/projectId" | tail -n 1)
PROJECTID_LABEL=$(/srv/jupyterhub/kubectl get namespace "${NAMESPACE}" -o custom-columns="${NAMESPACE}:metadata.labels.field\.cattle\.io\/projectId" | tail -n 1)

echo "c.JupyterHub.spawner_class = 'kubespawner.KubeSpawner'" >> /srv/jupyterhub/jupyterhub_config.py

#echo "c.KubeSpawner.hub_connect_url = 'http://jupyterhub-np.default.svc.cluster.local:8000'" >> /srv/jupyterhub/jupyterhub_config.py
#echo "c.KubeSpawner.hub_connect_url = 'http://keras.ics.muni.cz:8000'" >> /srv/jupyterhub/jupyterhub_config.py
echo "c.KubeSpawner.hub_connect_url = 'http://jupyterhub-ingress.handl-ns.svc.cluster.local:80'" >> /srv/jupyterhub/jupyterhub_config.py

echo "c.KubeSpawner.enable_user_namespaces = True" >> /srv/jupyterhub/jupyterhub_config.py
echo "c.ResourceReflector.omit_namespace = False" >> /srv/jupyterhub/jupyterhub_config.py

# Set the same Rancher's project label and annotation to the new namespaces
echo "c.KubeSpawner.user_namespace_labels = {'field.cattle.io/projectId': '${PROJECTID_LABEL}'}" >> /srv/jupyterhub/jupyterhub_config.py
echo "c.KubeSpawner.user_namespace_annotations = {'field.cattle.io/projectId': '${PROJECTID_ANNOTATION}'}" >> /srv/jupyterhub/jupyterhub_config.py

echo "c.KubeSpawner.user_namespace_template = '{username}-ns'" >> /srv/jupyterhub/jupyterhub_config.py

# SecurityContext of the spawned notebooks
echo "c.KubeSpawner.container_security_context = {'privileged':False,'runAsUser':1000,'runAsGroup':1000,'allowPrivilegeEscalation':False,'capabilities':{'drop':['ALL']}}" >> /srv/jupyterhub/jupyterhub_config.py
echo "c.KubeSpawner.pod_security_context = {'runAsNonRoot':True,'seccompProfile':{'type':'RuntimeDefault'}}" >> /srv/jupyterhub/jupyterhub_config.py

echo "c.JupyterHub.authenticator_class = 'jupyterhub.auth.DummyAuthenticator'" >> /srv/jupyterhub/jupyterhub_config.py
echo "c.DummyAuthenticator.password = '${JUPYTERHUB_PASSWORD}'" >> /srv/jupyterhub/jupyterhub_config.py
#echo "c.DummyAuthenticator.auto_login = True" >> /srv/jupyterhub/jupyterhub_config.py

sleep infinity
