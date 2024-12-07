# fluentbit 설치
kubectl create sa -n logging fluent-bit
kubectl delete -f fluentbit.yaml
kubectl apply -f fluentbit.yaml

# fluentbit 파드 상태 및 로그 확인
kubectl get pod -n logging
kubectl logs -n logging ds/fluent-bit