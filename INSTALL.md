# Running Open Data Maker on your computer

## Install Prerequisites

Before you can run Open Data Maker, you'll need to have the following software
installed on your computer:
* [Elasticsearch]
* [Ruby] 2.2.2

### Mac OS X

On a Mac, we recommend installing Ruby 2.2.2 via [RVM], and Elasticsearch via
[Homebrew]. If you are contributing to development, you will also need [Git].
If you don't already have these tools, the 18F [laptop] script will install
them for you.

## Get the Source Code

For development, [fork](http://help.github.com/fork-a-repo/) the repo
first, then clone your fork.

```
git clone https://github.com/<your GitHub username>/open-data-maker.git
cd open-data-maker
```

If you just want to install and run, then you can just download a
[zip file](https://github.com/18F/open-data-maker/archive/master.zip).

## Install dependencies
The bootstrap script will make sure you have all the dependencies, and will
also install and start up Elasticsearch:

```
script/bootstrap
```

## Run the App

### Make sure Elasticsearch is up and running
If you just ran `script/bootstrap`, then Elasticsearch should already be
running. But if you stopped it or restarted your computer, you'll need to
start it back up. Assuming you installed Elasticsearch via our `bootstrap`
script, you can restart it with this command:

```brew services restart elasticsearch```

### Start the app

```
padrino start
```
Go to: http://127.0.0.1:3000/

and you should see the text `Welcome to Open Data Maker` with a link to
the API created by the [sample data](sample-data).  

You can verify that the import was successful by visiting
http://127.0.0.1:3000/cities?name=Cleveland. You should see something like:

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

If you set the `DATA_PATH` environment variable to reference a new dataset,
it will be imported when the app starts up.  

The data directory can optionally include a file called `data.yaml` (see [the sample one](sample-data/data.yaml) for its schema) that references one or more `.csv` files and specifies data types,
field name mapping, and other.

The app will check the version
in that file and if it is new, the old index (of the same name) will be
removed and re-created.

### Importing Data Manually

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

you may alternatly delete all the indices (which could affect other apps if
they are using your local elasticsearch)

```
rake es:delete[_all]
```

## Want to help?

See [Contribution Guide](CONTRIBUTING.md)

[Elasticsearch]: https://www.elastic.co/products/elasticsearch
[Homebrew]: http://brew.sh/
[RVM]: https://github.com/wayneeseguin/rvm
[rbenv]: https://github.com/sstephenson/rbenv
[Ruby]: https://www.ruby-lang.org/en/
[Git]: https://git-scm.com/
[laptop]: https://github.com/18F/laptop
