cd /home/vagrant/bgoat-inception-of-things-p3
sed -i 's/wil42\/playground\:v1/wil42\/playground\:v2/g' ./manifests/deployment.yaml 
git add manifests/deployment.yaml
git commit -m "v2"
export GIT_PASS=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d ) ; git push http://root:${GIT_PASS}@gitlab.192.168.56.110.nip.io:8080/root/bgoat-inception-of-things-p3.git 