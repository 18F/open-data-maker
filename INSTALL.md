# Running Open Data Maker on your computer

If you just want to install and run, then you can just download a
[zip file](https://github.com/18F/open-data-maker/archive/master.zip).

You will still need the the dependencies below, but you don't need to
clone the git repo for the source code.

## Install Prerequisites

You can run our bootstrap script to make sure you have all the dependencies.
It will also install and start up Elasticsearch:

```
script/bootstrap
```

To run Open Data Maker, you will need to have the following software installed on your computer:
* [Elasticsearch] 1.7.3
* [Ruby] 2.2.2

**NOTE: Open Data Maker does not currently work with Elasticsearch versions 2.x and above.**
You can follow or assist our progress towards 2.x compatibility [at this GitHub issue](https://github.com/18F/open-data-maker/issues/248).

### Mac OS X

On a Mac, we recommend installing Ruby 2.2.2 via [RVM], and Elasticsearch 1.7.3 via
[Homebrew].  If you don't want to use the bootstrap script above, you can install
elasticsearch 1.7 with brew using the following command:

```
brew install elasticsearch17
```

If you are contributing to development, you will also need [Git].
If you don't already have these tools, the 18F [laptop] script will install
them for you.

## Get the Source Code

For development, [fork](http://help.github.com/fork-a-repo/) the repo
first, then clone your fork.

```
git clone https://github.com/<your GitHub username>/open-data-maker.git
cd open-data-maker
```

## Run the App

### Make sure Elasticsearch is up and running
If you just ran `script/bootstrap`, then Elasticsearch should already be
running. But if you stopped it or restarted your computer, you'll need to
start it back up. Assuming you installed Elasticsearch via our `bootstrap`
script, you can restart it with this command:

```brew services restart elasticsearch```


### Import the data

To get started, you can import sample data with:

`rake import`

### Start the app

```
padrino start
```
Go to: http://127.0.0.1:3000/

and you should see the text `Welcome to Open Data Maker` with a link to
the API created by the [sample data](sample-data).  

You can verify that the import was successful by visiting
http://127.0.0.1:3000/v1/cities?name=Cleveland. You should see something like:

```json
{
  "state": "OH",
  "name": "Cleveland",
  "population": 396815,
  "land_area": 77.697,
  "location": {
    "lat": 41.478138,
    "lon": -81.679486
  }
```

### Custom Datasets

While the app is running (or anytime) you can run `rake import`. For instance, if you had a `presidents/data.yaml` file, you would import
it with:

```sh
export DATA_PATH=presidents
rake import
# or, more succintly:
DATA_PATH=presidents rake import
```

to clear the data, assuming the data set  had an index named "president-data"

```
rake es:delete[president-data]
```

you may alternately delete all the indices (which could affect other apps if
they are using your local Elasticsearch)

```
rake es:delete[_all]
```

The data directory can optionally include a file called `data.yaml` (see [the sample one](sample-data/data.yaml) for its schema) that references one or more `.csv` files and specifies data types,
field name mapping, and other support data.

## Experimental web UI for indexing

Optionally, you can enable indexing from webapp, but this option is still experimental:
* `export INDEX_APP=enable`
* in your browser, go to /index/reindex

the old index (if present) will be deleted and re-created from source files at DATA_PATH.

## Want to help?

See [Contribution Guide](CONTRIBUTING.md)

Read additional [implementation notes](NOTES.md)

[Elasticsearch]: https://www.elastic.co/products/elasticsearch
[Homebrew]: http://brew.sh/
[RVM]: https://github.com/wayneeseguin/rvm
[rbenv]: https://github.com/sstephenson/rbenv
[Ruby]: https://www.ruby-lang.org/en/
[Git]: https://git-scm.com/
[laptop]: https://github.com/18F/laptop
