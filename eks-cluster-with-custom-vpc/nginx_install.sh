kubectl create deployment nx --image=nginx --replicas=3
kubectl expose deployment nx --type=LoadBalancer --port=80 --target-port=80
kubectl get svc -w 