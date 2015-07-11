# Running Open Data Maker on your computer

## Install Prerequisites

Before you can run Open Data Maker, you'll need to have the following software
installed on your computer:
* [Elasticsearch]
* [Ruby] 2.2+

If you are contributing to development you will also need [Git].  

Our install instructions are focused on the Mac platform, we recommend: [RVM][RVM] (or rbenv),
and [Homebrew][Homebrew].

If you already have all of the prerequisites installed, you can skip
to the [Open Data Maker Installation](#install-open-data-maker).

## Install Open Data Maker

### Clone the repo to your machine

For development, [fork](http://help.github.com/fork-a-repo/) the repo
first, then clone your fork.

```
git clone https://github.com/<your GitHub username>/open-data-maker.git && cd open-data-maker
```

If you just want to install, then you can just download a [zip file]().

### Install the dependencies

```
script/bootstrap
```

### Run the App

Make sure you are running Elastic Search: ```brew services restart elasticsearch```
if you installed with homebrew on OSX.

```
padrino start
```
Go to: http://127.0.0.1:3000/

and you should see the text `Welcome to Open Data Maker`.

The installation script also imported some sample data for you.
You can verify that the import was successful by visiting
http://127.0.0.1:3000/cities?name=Cleveland. You should see something like:

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

to restart with new data (deleting all the indices):
```
rake delete:all
```

## Want to help?

See [Contribution Guide](CONTRIBUTING.md)

[Elasticsearch]: https://www.elastic.co/products/elasticsearch
[Homebrew]: http://brew.sh/
[RVM]: https://github.com/wayneeseguin/rvm
[Ruby]: https://www.ruby-lang.org/en/
[Git]: https://git-scm.com/
