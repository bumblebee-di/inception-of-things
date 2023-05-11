# command for checking ports:
# sudo netstat -tulpn

sudo apt-get update &&
sudo apt-get -y upgrade &&
sudo apt-get install curl net-tools -y &&

# НУЖНО локально ставить аргоцд??? https://yashguptaa.medium.com/application-deploy-to-kubernetes-with-argo-cd-and-k3d-8e29cf4f83ee

# Install ArgoCD locally on Debian DOESN'T WORK!!!! or maybe need to try once more ( https://argo-cd.readthedocs.io/en/stable/cli_installation/ )
# curl -sSL -o argocd-darwin-amd64 https://github.com/argoproj/argo-cd/releases/download/$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')/argocd-darwin-amd64
# sudo install -m 555 argocd-darwin-amd64 /usr/local/bin/argocd
# rm argocd-darwin-amd64
# OTHER INSTRUCTION: https://argo-cd.readthedocs.io/en/stable/cli_installation/ ) ВРОДЕ РАБОТАЕТ
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

printf "==========\n\033[32mInstalling docker\033[0m\n==========\n"
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh ./get-docker.sh &&

sudo usermod -aG docker $USER

printf "==========\n\033[32mInstalling kubectl\033[0m\n==========\n"
# Download latest stable version of kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
# Download sha256 hash sum for just installed kubectl and check it
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" &&
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check &&
# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&

# Install k3d
printf "==========\n\033[32mInstalling k3d\033[0m\n==========\n"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash &&

# Add autocompletion
echo "source <(k3d completion bash)" >> ~/.bashrc
source ~/.bashrc

# Install Helm
printf "==========\n\033[32mInstalling Helm\033[0m\n==========\n"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &&
sudo chmod 700 get_helm.sh &&
sudo ./get_helm.sh &&

echo "->creating k3d cluster:"
sudo k3d cluster create bonus \
	--port 8080:80@loadbalancer \
	--port 8888:30080@agent:0 --agents 1

sleep 60

echo "->Installing gitlab:"
sudo kubectl create namespace gitlab

while 
  sudo helm repo add gitlab https://charts.gitlab.io/
  [ $? -gt 0 ]
do :; done

sudo helm install -n gitlab gitlab gitlab/gitlab -f /home/vagrant/confs/values-minimal.yaml 

echo "->Installing AgoCD"
sudo kubectl create namespace argocd
curl https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml | sudo kubectl apply -n argocd -f -

# sleep 30
while 
  sudo kubectl wait --for=condition=Ready pods --all -n argocd 
  [ $? -ne 0 ]
do :; done

sudo kubectl -n argocd set env deployment/argocd-server ARGOCD_SERVER_INSECURE=true

sudo kubectl create namespace dev
echo "->Setup ingress and wilsApps"
kubectl apply -n argocd -f ./confs/ingress-argocd.yaml
sudo kubectl apply -n gitlab -f ./confs/ingress-gitlab.yaml

while 
  sudo kubectl get secret  gitlab-gitlab-initial-root-password -n gitlab
  [ $? -ne 0 ]
do :; done

export GIT_PASS=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d )
sed -i "s/password:/password: ${GIT_PASS}/g" ./confs/secret.yaml

sudo kubectl apply -f ./confs/secret.yaml -n argocd

echo "->Wait for gitlab to be ready"
sudo kubectl wait --for=condition=complete -n gitlab --timeout=600s job/gitlab-migrations-1

echo " ----> Commandes suivantes : Create first repo with the UI"
git clone  --branch nodeport https://github.com/bumblebee-di/inception-of-things-p3.git
cd inception-of-things-p3
git remote set-url origin http://gitlab.192.168.56.110.nip.io:8080/root/inception-of-things-p3.git
git config --global --add safe.directory /home/vagrant/inception-of-things-p3
# git push origin master
git config --global user.name "root"
git push http://root:${GIT_PASS}@gitlab.192.168.56.110.nip.io:8080/root/inception-of-things-p3.git
cd ..

# sudo kubectl port-forward svc/argocd-server -n argocd 8433:443  --address=0.0.0.0 > /dev/null 2>&1 &

sleep 10
echo "---> don't forget to apply wilsapp after creating and updating the repo"
sudo kubectl apply -n argocd -f /home/vagrant/confs/app.yaml


sleep 15
sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo
sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d ; echo

sudo kubectl -n argocd set env deployment/argocd-server ARGOCD_SERVER_INSECURE=true