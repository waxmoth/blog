---
title: MySQL NDB cluster in Kubernetes
date: 2022-06-09 06:07:33
tags: mysql, db cluster, k8s
---

### What we can learn from this post?

- Install the [MySQL NDB Cluster](https://www.mysql.com/products/cluster/) into your Kubernetes cluster;
- How to use NDB cluster

### Deploy the [NDB operator](https://github.com/mysql/mysql-ndb-operator) into k8s node

The MySQL NDB Operator is a k8s operator, use it to manage the NDB cluster.

1. Use the office configure to deploy it

```shell
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-ndb-operator/main/deploy/manifests/ndb-operator.yaml
```

2. Check the operator pods

```shell
kubectl get pods -n ndb-operator
```

The output should be similar with:

```text
NAME                                          READY   STATUS    RESTARTS   AGE
ndb-operator-app-54d6f946d5-cmpjb             1/1     Running   0          2m54s
ndb-operator-webhook-server-c66cbd8bc-sk56c   1/1     Running   0          2m54s
```

### Create a NDB Cluster

```yaml
apiVersion: mysql.oracle.com/v1alpha1
kind: NdbCluster
metadata:
  name: mysql-ndb
spec:
  nodeCount: 2 # Number of Data Nodes
  redundancyLevel: 2 # MySQL Cluster Replica
  dataNodeConfig:
    DataMemory: 100M
    MaxNoOfTables: 1024
    MaxNoOfConcurrentOperations: 409600
    Arbitration: WaitExternal
  dataNodePVCSpec:
    storageClassName: manual
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 20Gi
  mysqld:
    nodeCount: 2 # Number of MySQL Servers

    myCnf: |
      [mysqld]
      max-user-connections = 42
      ndb-extra-logging = 20
      expire-logs-days = 30

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ndb-pv1
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/ndb_data/node1"
    type: DirectoryOrCreate

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ndb-pv2
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/ndb_data/node2"
    type: DirectoryOrCreate
```

From the above configure, we can deploy the NDB cluster into the k8s. It includes two SQL nodes and two Data Nodes.

```shell
kubectl apply -f k8s/ndb.yaml
```

To get the example `mysql-ndb` cluster pods

```shell
kubectl get pods -l mysql.oracle.com/v1alpha1=mysql-ndb
```

The output is similar with:

```text
NAME                                READY   STATUS    RESTARTS    AGE
mysql-ndb-mgmd-0                    1/1     Running   0           5m10s
mysql-ndb-mgmd-1                    1/1     Running   0           3m5s
mysql-ndb-mysqld-5549c5b96c-b4ck6   1/1     Running   0           1m10s
mysql-ndb-mysqld-5549c5b96c-tfbdl   1/1     Running   0           1m10s
mysql-ndb-ndbd-0                    1/1     Running   0           5m10s
mysql-ndb-ndbd-1                    1/1     Running   0           5m10s
```

For the above output, we can see the cluster contains two management nodes `*-mgmd-*`, two data nodes `*-ndbd-*`
and two MySQL servers `*-mtsqld-*`.

### Connect to the NDB cluster

Get the cluster's services

```shell
kubectl get services -l mysql.oracle.com/v1alpha1=mysql-ndb
```

The output would be similar with:

```text
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
mysql-ndb-mgmd     ClusterIP   10.104.206.41   <none>        1186/TCP   1d18h
mysql-ndb-mysqld   ClusterIP   10.106.0.201    <none>        3306/TCP   1d18h
mysql-ndb-ndbd     ClusterIP   None            <none>        1186/TCP   1d18h
```

Now we can connect to the MySQL service by the service name `mysql-ndb-mysqld` and 3306 port.
The password for root user can get from this command:

```shell
kubectl get secret $(kubectl get ndb mysql-ndb -o jsonpath={.status.generatedRootPasswordSecretName}) \
    -o jsonpath={.data.password} | base64 -d
```

#### Connect to MySQL in one K8s pod

```shell
kubectl exec -it mysql-ndb-mysqld-5549c5b96c-b4ck6 -- bash
```

- Connect through the `mysql`

```shell
mysql -h mysql-ndb-mysqld -u root -p
```

- Use NDB tool to connect the Management Server `mysql-ndb-mgmd`

```shell
ndb_mgm -c mysql-ndb-mgmd

-- NDB Cluster -- Management Client --
ndb_mgm> show
Connected to Management Server at: mysql-ndb-mgmd:1186
Cluster Configuration
---------------------
[ndbd(NDB)]     2 node(s)
id=3    @172.17.0.15  (mysql-8.0.29 ndb-8.0.29, Nodegroup: 0, *)
id=4    @172.17.0.7  (mysql-8.0.29 ndb-8.0.29, Nodegroup: 0)

[ndb_mgmd(MGM)] 2 node(s)
id=1    @172.17.0.3  (mysql-8.0.29 ndb-8.0.29)
id=2    @172.17.0.8  (mysql-8.0.29 ndb-8.0.29)

[mysqld(API)]   8 node(s)
id=145  @172.17.0.4  (mysql-8.0.29 ndb-8.0.29)
id=146  @172.17.0.10  (mysql-8.0.29 ndb-8.0.29)
id=147 (not connected, accepting connect from any host)
id=148 (not connected, accepting connect from any host)
id=149 (not connected, accepting connect from any host)
id=150 (not connected, accepting connect from any host)
id=151 (not connected, accepting connect from any host)
id=152 (not connected, accepting connect from any host)
```

#### Connect to MySQL from outside K8s

The default NDB Cluster no expose for outside, we need to enable the load balancers to enable access from outside

```shell
kubectl patch ndb mysql-ndb --type='merge' \
    -p '{"spec":{"enableManagementNodeLoadBalancer":true,"mysqld":{"enableLoadBalancer":true}}}'
```

We can check the expose ports from this command:

```shell
kubectl get services -l mysql.oracle.com/v1alpha1=mysql-ndb
```

The output will be similar as:

```text
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
mysql-ndb-mgmd     LoadBalancer   10.104.206.41   <pending>     1186:31367/TCP   1d4h
mysql-ndb-mysqld   LoadBalancer   10.106.0.201    <pending>     3306:30783/TCP   1d4h
mysql-ndb-ndbd     ClusterIP      None            <none>        1186/TCP         1d4h
```

Connect through mysql tool

```shell
mysql -h $(minikube ip) -P 30783 -u root -p
```
