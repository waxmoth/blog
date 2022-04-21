---
title: How to use LocalStack in Kubernetes
date: 2022-04-21 01:14:04
tags: k8s,localstack,docker,minikube
---

### What we can learn from this post?
- Deploy the LocalStack into your Kubernetes cluster;
- How to use the local AWS services in LocalStack.

### Install the Helm and use it to deploy the LocalStack into k8s

The [LocalStack](https://localstack.cloud/) is a fully functional local cloud stack, which we can use to develop and test the serverless apps offline.
We can use Helm to deploy the LocalStack into k8s
```shell
sudo snap install helm --classic
helm repo add localstack-repo https://helm.localstack.cloud
helm upgrade --install localstack localstack-repo/localstack
```

To get the services host
```shell
export EDGE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services localstack)
export LOCALSTACK_HOST=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
echo http://$LOCALSTACK_HOST:$EDGE_PORT
```

The output is similar to:
```shell
http://192.168.49.2:31566
```

### Add persistent volume for the localstack
Deploy one volume into the cluster by using follows configures
```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: localstack-pv
  labels:
    type: local
spec:
  storageClassName: standard
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  hostPath:
    path: /data/localstack
    type: DirectoryOrCreate

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: localstack-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  volumeName: localstack-pv
```

Redeploy the LocalStack to load the volume. For more parameters please refer [document](https://github.com/localstack/helm-charts/blob/main/charts/localstack/README.md#parameters)
```shell
helm upgrade localstack localstack-repo/localstack --set-string persistence.enabled=true,persistence.size=50Gi,ingress.enabled=true,persistence.storageClass=standard,persistence.existingClaim=localstack-pvc
```

### Testing the S3 service from LocalStack
- To better and easy use the LocalStack, we can install the tool [aws-local](https://github.com/localstack/awscli-local)
```shell
pip install awscli-local

# Special environments for the aws-local
export LOCALSTACK_HOST=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
export EDGE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services localstack)
```

- Create a bucket
```shell
awslocal s3 mb s3://test-bucket
# The output should be:
>> make_bucket: test-bucket
```

- Copy files or sync folder into the bucket
```shell
awslocal s3 sync ./public s3://test-bucket
```

- List files from the bucket
```shell
awslocal s3 ls s3://test-bucket

# The output will be:
                           PRE 2022/
                           PRE archives/
                           PRE css/
                           PRE img/
                           PRE js/
                           PRE libs/
                           PRE tags/
2022-04-21 10:20:02        766 favicon.ico
2022-04-21 10:20:02       4650 index.html
```

- Copy one file from S3
```shell
awslocal s3 cp s3://test-bucket/index.html /tmp/index.html
```

- Delete files from S3
```shell
awslocal s3 rm s3://test-bucket/index.html
```

- Use the local S3 from the client SDK. For example: [aws-sdk-php](https://github.com/aws/aws-sdk-php)
The S3 SDK default use virtual hosted-style as the S3 url. _<bucket-name>.s3.<region>.localhost.localstack.cloud_
We can override the configures to force use the path-style endpoint
```yml
{
  endpoint: 'http://minikube:31566',
  use_path_style_endpoint: true
}
```
