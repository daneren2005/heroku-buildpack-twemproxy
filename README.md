# heroku-buildpack-twemproxy
Run twemproxyin a dyno along with your application
https://github.com/twitter/twemproxy

Run locally: ```
bin/compile /tmp/build /tmp/cache
mkdir ~/app/bin
cp /tmp/build/bin/* ~/app/bin/
chmod +x ~/app/bin/*

sudo mkdir -p /app/vendor/twemproxy
sudo cp -R /tmp/build/vendor/twemproxy/ /app/vendor/twemproxy/
sudo chmod -R 777 /app/vendor/

bin/start-twemproxy
```
