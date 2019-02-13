# heroku-buildpack-twemproxy
Run twemproxyin a dyno along with your application
https://github.com/twitter/twemproxy

Run locally:
```
bin/compile /tmp/build /tmp/cache
mkdir ~/app/bin
cp /tmp/build/bin/* ~/app/bin/
chmod +x ~/app/bin/*

mkdir -p ~/app/vendor/twemproxy
cp -R /tmp/build/vendor/twemproxy/ ~/app/vendor/twemproxy

bin/start-twemproxy
```
