---
title: How to deploy your blog into k8s
date: 2022-01-10 02:45:59
tags: kubernetes, k8s, hexo, blog
---

### What we can learn from this post?
- Build the blog image;
- Deploy your blog image into the local K8s cluster.

### Tools that needed:
- [Docker](https://www.docker.com/) 
- [Minikube](https://minikube.sigs.k8s.io/docs/) a tool to deploy and running your local k8s cluster

### Steps
1. Update the [Dockefile](https://github.com/waxmoth/blog/blob/master/.docker/nginx/Dockerfile) copy the statics files into NGINX
```dockerfile
FROM node_base AS node_build
RUN npm install
# Build static pages
RUN npm run clean && npm run build


FROM nginx_base
# Copy statics into webservice
COPY --from=node_build ./public /data/sites/blog
COPY .docker/nginx/conf/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/conf/app.conf.template /etc/nginx/conf.d/app.conf.template
```

2. Build your docker images into the k8s cluster
```bash
eval $(minikube docker-env)
docker build -t node-base -f .docker/node/Dockerfile .
docker build -t nginx-base -f .docker/nginx/Dockerfile ./.docker/nginx
```
- Build the blog image
```bash
docker build -t blog-nginx -f .docker/nginx/Dockerfile.k8s .
```

- Check the built images
```bash
minikube image ls|grep blog
```
The output should be:
```bash
docker.io/library/blog-nginx:latest
```

3. Create the env for k8s
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: blog-configmap
  namespace: default
data:
  SITE: blog.example.com
```

4. Create the deployment configures for k8s
- The service configure
```yaml
apiVersion: v1
kind: Service
metadata:
  name: blog
  labels:
    name: blog
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
  type: NodePort
  selector:
    name: blog
```

- The deployment configure
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: blog
  name: blog
spec:
  replicas: 1
  selector:
    matchLabels:
      name: blog
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        name: blog
    spec:
      containers:
        - envFrom:
            - configMapRef:
                name: blog-configmap
          image: blog-nginx:latest
          imagePullPolicy: IfNotPresent
          name: blog
          ports:
            - containerPort: 80
      restartPolicy: Always
```

- Create TLS secret for HTTPS
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout .docker/nginx/letsencrypt/blog.key \
        -out .docker/nginx/letsencrypt/blog.crt -subj "/CN=blog.example.com/O=example.com"
kubectl create secret tls blog-tls --cert=.docker/nginx/letsencrypt/blog.crt \
        --key=.docker/nginx/letsencrypt/blog.key
```

- Add the [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) configure to expose the service
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: blog-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
    - hosts:
        - blog.example.com
      secretName: blog-tls
  ingressClassName: nginx
  rules:
    - host: blog.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: blog
                port:
                  number: 80
```

5. Deploy the blog into minikube
```bash
kubectl apply -f k8s/
```

6. Verify the blog service and expose ports
```bash
kubectl get service blog
```
The output is similar as:
```
NAME   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
blog   NodePort   10.105.72.160   <none>        80:30500/TCP,443:30211/TCP   5m
```

7. Get blog url
```bash
minikube service blog --url
```
The output is similar to:
```
http://192.168.49.2:30500
http://192.168.49.2:30211
```

8. Modifier the hosts
```
sudo -- sh -c "echo '$(minikube ip) blog.example.com' >> /etc/hosts"
```

9. Check it in browser and enjoy your blog
```
https://blog.example.com/
```
