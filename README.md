

# Open Data Maker
[![Build Status](https://travis-ci.org/18F/open-data-maker.svg?branch=master)](https://travis-ci.org/18F/open-data-maker)

The goal of this project is to make it easy to turn a lot of potentially large
csv files into open data via an API and the ability for people to download
smaller csv files with a subset of the data.

Preliminary research suggests that open data users (journalists and others)
actually know how to work with spreadsheets really well, but a lot of the
data sets that we have in government are huge.

The first version of this project will allow us to host a website for an
agency with a specific set of csv files, which are deployed with the app.
This will allows us to deploy more quickly since there will be a lower risk
security profile than if an agency could upload the CSV files (which might
be a nice longer term feature).


## Install and Run the App (as a developer)

See our [Installation Guide](INSTALL.md)

## How this works

By default, data will be loaded from /sample-data

* [cities100.csv](sample-data/cities100.csv) - dataset of 100 most populous cities in the US
* [data.yaml](sample-data/data.yaml) - configuration for
  * how columns are mapped to fields in json output
  * index name *city-data*
  * api endpoint name *cities*

When you run the app (after ```rake import```), you can query the dataset via json API, like: /cities?name=Chicago

To use your own data, you can set a different directory with

```
export export DATA_PATH='./data'
```

1. Put csv files into /data
1. Import files from /data: ```rake import```
   1.1 there can be multiple files (must end in .csv)
   1.1 optional data.yaml file that specifies column -> field mapping, index and API endpoint
1. api endpoint to get the data /api?name=value

## Help Wanted

1. Try out importing multiple data sets with different endpoints and data.yaml configuration
2. Take a look at our [open issues](https://github.com/18F/open-data-maker/issues) and our [Contribution Guide](CONTRIBUTING.md)

## More Info

Here's how it might look in the future:

![overview of data types, prompt to download data, create a custom data set, or look at API docs](/doc/data-overview.png)


![Download all the data or make choices to create a csv with a subset](/doc/csv-download.png)
