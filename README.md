# Blog
Try to write and record things? Why not write a [Hexo](https://github.com/hexojs/hexo/) blog?

## How to use it?
* Copy and set your blog environment values
```shell script
cp .env.dist .env
cp _config.yml.dist _config.yml
```

* Add SSL certificates for your site from certbot **OPTIONAL**
```shell
sudo docker run --rm -it -v "${PWD}/.docker/nginx/letsencrypt:/etc/letsencrypt/" \
    -p 80:80 certbot/certbot certonly --standalone -d ${SITE}
```

* Build docker images
```shell script
docker-compose build
```

* Install some [HEXO themes](https://hexo.io/themes/) if needed
```bash
git --git-dir=/dev/null clone --depth=1 https://github.com/sanjinhub/hexo-theme-geek.git themes/geek

# Modifier the _config.yml set the theme as geek

# Modifier the configures in the themes
# vim themes/geek/_config.yml
```

* Install required NodeJS libraries
```shell script
docker-compose run --rm node bash -c "npm install"
```

* Build and publish your post?
```shell script
docker-compose run --rm node bash -c "npm run clean && npm run build"
```

* Run and enjoy your blog
```shell script
docker-compose up -d
```

* Create a draft post 
```shell script
docker-compose run --rm node bash -c "npm run create-draft 'Example post'"
```

* Publish your post
```shell script
docker-compose run --rm node bash -c "npm run publish 'Example post'"
```
