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

and you should see the text `Welcome to Open Data Maker`. Next, it's time to load
some data

## Load a Dataset

Of course, there is nothing to see here yet until we load some data. We can start
by loading the sample `cities` dataset with the command `rake import`. After this
completes, the query http://127.0.0.1:3000/cities?name=Cleveland should return
something like

```json
{
  "state": "OH",
  "name": "Cleveland",
  "population": "396815",
  "latitude": "41.478138",
  "longitude": "-81.679486"
}
```

### Custom Datasets
To load a custom dataset, you'll need to set the `DATA_PATH` environment
variable to the path of your data directory and run `rake import` again. Your
data directory should include a `data.yaml` (see [the sample
one](sample-data/data.yaml) for its schema) that references one or more `.csv`
files. For instance, if you had a `presidents/data.yaml` file, you would import
it with:

```sh
export DATA_PATH=presidents
rake import
# or, more succintly:
DATA_PATH=presidents rake import
```

## Want to help?

See [Contribution Guide](CONTRIBUTING.md)


[elasticsearch]: https://www.elastic.co/products/elasticsearch
