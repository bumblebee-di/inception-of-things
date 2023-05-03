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

printf "==========\nInstalling docker\n==========\n"
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh ./get-docker.sh &&

sudo usermod -aG docker $USER

printf "==========\nInstalling kubectl\n==========\n"
# Download latest stable version of kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
# Download sha256 hash sum for just installed kubectl and check it
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" &&
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check &&
# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&

# Install k3d
printf "==========\nInstalling k3d\n==========\n"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash &&

# Add autocompletion
echo "source <(k3d completion bash)" >> ~/.bashrc
source ~/.bashrc

# Install cluster
# https://www.sokube.io/en/blog/gitops-on-a-laptop-with-k3d-and-argocd-en

printf "==========\nCreating cluster\n==========\n"
# sudo k3d cluster create mycluster -p "8080:30080@agent:0" --agents 2
sudo k3d cluster create iot -p "8888:30080@agent:0" --agents 1 &&
printf "==========\nCreating namespaces\n==========\n"
sudo kubectl create namespace argocd &&
sudo kubectl create namespace dev &&

# Install ArgoCD into argocd NAMESPACE
# https://yashguptaa.medium.com/application-deploy-to-kubernetes-with-argo-cd-and-k3d-8e29cf4f83ee

sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml &&
printf "==========\nWaiting for pods\n"
sleep 40 && #??? for pods gets up
printf "==========\n"
# OR
# sudo kubectl wait --for=condition=Ready pods --all -n argocd &&

# check nodes on argocd namespace
printf "==========\nGet pods\n==========\n"
sudo docker ps &&
sudo kubectl get pods -n argocd &&
sudo kubectl get nodes -n argocd &&
sudo kubectl get svc -n argocd &&

# OR https://bcrypt-generator.com/
# sudo kubectl -n argocd patch secret argocd-secret
#   -p '{"stringData":  {
#     "admin.password": "$2a$12$6FIwz3pyhYL.H2yTxePgWu.LJLrUTItSMcln/pJIF9t9K7ypIKddO",
#     "admin.passwordMtime": "'$(date +%FT%T%Z)'"
#   }}'

sudo kubectl port-forward svc/argocd-server -n argocd 8080:443  --address=0.0.0.0 > /dev/null 2>&1 &

sudo kubectl apply -f /home/vagrant/confs/project.yaml -n argocd
sudo kubectl apply -f /home/vagrant/confs/app.yaml -n argocd

# # check nodes on argocd namespace
# # kubectl get pods -n argocd


# Получить пароль в декодированном виде:
echo "==========get password=========="
sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d > $HOME/.pass
echo "================================"

# argocd login localhost:8080
# argocd app create playground --repo https://github.com/bumblebee-di/inception-of-things-p3.git --path manifests --dest-server https://kubernetes.default.svc --dest-namespace dev
# sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d ; echo

# sudo kubectl port-forward app-deployment-85dd49fff8-v6kgj -n dev 8888:8888 --address-0.0.0.0 > /dev/null 2>&1
