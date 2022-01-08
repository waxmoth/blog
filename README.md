# Blog
Try to write and record things? Why not write a [Hexo](https://github.com/hexojs/hexo/) blog?

## How to use it?
* Copy and set your blog environment values
```shell script
cp .env.dist .env
cp _config.yml.dist _config.yml
```

* Build image in your local
```shell script
docker-compose build
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
