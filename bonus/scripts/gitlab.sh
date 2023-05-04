sudo kubectl create namespace gitlab
sudo helm repo add gitlab https://charts.gitlab.io
curl https://gitlab.com/gitlab-org/charts/gitlab/-/raw/master/examples/values-minikube-minimum.yaml?inline=false > values-minimal.yaml

# https://docs.gitlab.com/charts/installation/command-line-options.html

sudo helm upgrade --install -n gitlab gitlab gitlab/gitlab -f values-minimal.yaml --set global.hosts.externalIP=192.168.56.110 --set global.hosts.domain=192.168.56.110.nip.io --set global.hosts.https=false

sudo git clone https://github.com/bumblebee-di/inception-of-things-p3.git

cd inception-of-things-p3 && sudo git remote set-url origin http://192.168.56.110.nip.io:8080/root/iot.git