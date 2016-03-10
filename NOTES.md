
## Data

Details about the data are specified by DATA_PATH/data.yaml.  
Where DATA_PATH is an environment variable, which may be:

* `s3://username:password@bucket_name/path`
* `s3://bucket_name/path`
* `s3://bucket_name`
* a local path like: `./data`


This file is loaded the first time it is needed and then stored in memory.  The contents of `data.yaml` are stored as JSON in Elasticsearch in a single document of type `config` with id `1`.  

The version field of this document is checked at startup. If the new config has a new version, then we delete the whole index and re-index all of the files referred to in the `data.yaml` files section.

If no data.yml or data.yaml file is found, then all CSV files in `DATA_PATH` will be loaded, and all fields in their headers will be used.

## Debugging

`ES_DEBUG` environment variable will turn on verbose tracer in the Elasticsearch client

optional performance profiling for rake import: `rake import[profile=true]`
