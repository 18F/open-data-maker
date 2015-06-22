## Get Started

install
* ruby 2.2.2 (slightly older versions probably work)
* [elasticsearch], On OSX: ```brew install elasticsearch```

```
cd open-data-maker
gem install bundler && bundle install
```

## Run the App

Make sure elasticsearch is running.  If you installed with brew:
```
elasticsearch --config=/usr/local/opt/elasticsearch/config/elasticsearch.yml
```

Run the web app:
```
padrino start
```

go to: http://127.0.0.1:3000/

## Want to help?

See [Contribution Guide](CONTRIBUTING.md)


[elasticsearch]: https://www.elastic.co/products/elasticsearch
