# AWS 콘솔의 본인의의 IAM 역할과, Opensearch의 도메인 엔드포인트를 가져와서 각각 설정한다.
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
kubectl delete sa fluent-bit -n logging
# terraform namespace 옵션을 제거합니다.
terraform apply -auto-approve
# SA에 주석이 잘 들어갔는지 확인
kubectl get sa -n logging -oyaml fluent-bit

# fluentbit를 다시 apply를 통해 재배포 
kubectl apply -f aws_opensearch/fluentbit.yaml

# fluentbit 파드 상태 및 로그 확인
kubectl get pod -n logging
kubectl logs -n logging ds/fluent-bit