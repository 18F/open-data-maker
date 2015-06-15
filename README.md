
## Get Started

install ruby 2.2.2 (slightly older versions probably work)

```
brew install elasticsearch

cd open-data-maker
bundle
```

## Run the App

Make sure elasticsearch is running:
```
elasticsearch --config=/usr/local/opt/elasticsearch/config/elasticsearch.yml
```

Run the web app:
```
padrino start
```

go to: http://127.0.0.1:3000/


## Developer Notes

* [Padrino](http://www.padrinorb.com/) - Ruby Web framework
* [Liquid](http://liquidmarkup.org/) view templates
