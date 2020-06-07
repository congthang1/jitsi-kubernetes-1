# jitsimeet-k8s
jitsi meet installation on kubernetes

git clone https://github.com/varkalaramalingam/jitsi-kubernetes.git
cd jitsimeet-k8s/
ls
kubectl get all
kubectl get nodes

Install helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh

chmod u+x install-helm.sh

./install-helm.sh

kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --service-account tiller
kubectl get pods --namespace kube-system

Installing the Kubernetes Nginx Ingress Controller

helm install --name nginx-ingress stable/nginx-ingress --set controller.publishService.enabled=true

set dns record for ingress elb

Securing the Ingress Using Cert-Manager

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager.crds.yaml
kubectl create namespace cert-manager

helm repo add jetstack https://charts.jetstack.io

helm install --name cert-manager --version v0.14.1 --namespace cert-manager jetstack/cert-manager
vi production_issuer.yaml
-------------
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Email address used for ACME registration
    email: your_email_address
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Name of a secret used to store the ACME account private key
      name: letsencrypt-prod-private-key
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          class: nginx
--------------
kubectl create -f production_issuer.yaml
    • create test namespace
	kubectl create ns test

Note: change your domain name and namespace as per your requirement
Here, I am using minikube as my namespace and minikube.devopsk8s.cf as my domain name

if you want to change
sed -i 's/minikube/<your-namespce>/g' *
sed -i 's/minikube.devopsk8s.cf/<your-domainname>/g' configMap.yaml 

Important Note: You have to allow jvb service ports to public to make calls with more than 2 participants. 

    • Installing jitsi web service & deployment 
	kubectl apply -f web-service.yaml
	kubectl apply -f web-deployment.yaml
	kubectl get all -n test
    • Installing jitsi prosody service & deployment
kubectl apply -f prosody-service.yaml 
	kubectl apply -f prosody-deployment.yaml
	kubectl get all -n test
    • Installing jitsi jicofo deployment 
	kubectl apply -f jicofo-deployment.yaml
	kubectl get all -n test
    • Installing jitsi jvb service & deployment 
	kubectl apply -f jvb-service.yaml
	kubectl apply -f jvb-deployment.yaml
	kubectl get all -n test

    • Installing jitsi jibri deployment 
	kubectl apply -f jibri-deployment.yaml


root@kubectl:~/delete# kubectl get all -n test
NAME                           READY   STATUS    RESTARTS   AGE
pod/jicofo-596b54d48c-fl6rd    1/1     Running   0          19h
pod/jvb-57cc974b68-s4b75       1/1     Running   0          15h
pod/prosody-85d4c754bc-qjn5s   1/1     Running   0          24h
pod/web-6fddddc448-gltm5       1/1     Running   0          23h

NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE
service/jvb-tcp-udp   NodePort    10.100.210.15    <none>        30000:30000/TCP,31000:31000/UDP       7d
service/prosody       ClusterIP   10.100.189.114   <none>        5222/TCP,5280/TCP,5347/TCP,5269/TCP   7d
service/web           ClusterIP   10.100.147.92    <none>        80/TCP,443/TCP                        7d

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/jicofo    1/1     1            1           19h
deployment.apps/jvb       1/1     1            1           19h
deployment.apps/prosody   1/1     1            1           24h
deployment.apps/web       1/1     1            1           23h

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/jicofo-596b54d48c    1         1         1       19h
replicaset.apps/jvb-57cc974b68       1         1         1       15h
replicaset.apps/prosody-85d4c754bc   1         1         1       24h
replicaset.apps/web-6fddddc448       1         1         1       23h


Note: expose jvb node ports to public in security group.


---------------------------------
    • setup kubernetes ingress for jitsi web service
	kubectl apply -f web-ingress.yaml
    • To see deployment logs
	kubectl -n test logs -f deployment.apps/jvb
	kubectl -n test logs -f deployment.apps/jicofo
	kubectl -n test logs -f deployment.apps/prosody
	kubectl -n test logs -f deployment.apps/web
    • To see web ingress
	kubectl get ingresses. -n test
	kubectl describe certificate -n test



To deploy the Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

kubectl get deployment metrics-server -n kube-system

kubectl top node
kubectl top pod
