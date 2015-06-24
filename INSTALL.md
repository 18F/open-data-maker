# Running Open Data Maker on your computer

## Install Prerequisites

Before you can run Open Data Maker, you'll need to have the following software
installed on your computer: [Git], [Ruby] 2.2+, [RVM][RVM] (or rbenv),
[Elasticsearch], and [Homebrew][Homebrew] (for Mac users only).

If you already have all of the prerequisites installed, you can skip
to the [Open Data Maker Installation](#install-open-data-maker).

The easiest way to install everything on a Mac is to use the 18F [laptop]
script.

[laptop]: https://github.com/18F/laptop

## Install Open Data Maker

### Clone the repo to your machine
If you're an 18F employee, you can clone the repo directly:

```
git clone https://github.com/18F/open-data-maker.git && cd open-data-maker
```

Otherwise, you'll need to [fork](http://help.github.com/fork-a-repo/) the repo
first, then clone your fork.

```
git clone https://github.com/<your GitHub username>/open-data-maker.git && cd open-data-maker
```

### Install the dependencies

```
script/bootstrap
```

### Run the App

```
padrino start
```
Go to: http://127.0.0.1:3000/

and you should see the text `Welcome to Open Data Maker`.

The installation script also imported some sample data for you.
You can verify that the import was successful by visiting
http://127.0.0.1:3000/cities?name=Cleveland. You should see something like:

```
{
state: "OH",
name: "Cleveland",
population: "396815",
latitude: "41.478138",
longitude: "-81.679486"
}
```

## Want to help?

See [Contribution Guide](CONTRIBUTING.md)

[Elasticsearch]: https://www.elastic.co/products/elasticsearch
[Homebrew]: http://brew.sh/
[RVM]: https://github.com/wayneeseguin/rvm
[Ruby]: https://www.ruby-lang.org/en/
[Git]: https://git-scm.com/