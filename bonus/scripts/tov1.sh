cd /home/vagrant/inception-of-things-p3
sed -i 's/wil42\/playground\:v2/wil42\/playground\:v1/g' ./manifests/deployment.yaml 
git add manifests/deployment.yaml
git commit -m "v1"
export GIT_PASS=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 -d ) ; git push http://root:${GIT_PASS}@gitlab.192.168.56.110.nip.io:8080/root/inception-of-things-p3.git 