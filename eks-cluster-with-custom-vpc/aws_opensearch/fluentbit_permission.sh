export FLUENTBIT_ROLE='arn:aws:iam::445567110488:role/fluent-bit-irsa'
export ES_ENDPOINT='https://search-example-domain-6wgznvwngimspusqhtdykzgpu4.ap-northeast-2.es.amazonaws.com'

# Update the Elasticsearch internal database
curl -sS -u 'admin:Test1234!234' \
    -X PATCH \
    ${ES_ENDPOINT}/_opendistro/_security/api/rolesmapping/all_access?pretty \
    -H 'Content-Type: application/json' \
    -d'
[
  {
    "op": "add", "path": "/backend_roles", "value": ["'${FLUENTBIT_ROLE}'"]
  }
]
'


# fluentbit 설치
kubectl delete -f fluentbit.yaml
kubectl apply -f fluentbit.yaml

# fluentbit 파드 상태 및 로그 확인
kubectl get pod -n logging
kubectl logs -n logging ds/fluent-bit