

the config (specified by DATA_PATH/data.yaml) is loaded the first time it is needed and then stored in memory

(A) CloudFoundry: configuration is stored in Elastic Search in a single document of type 'config' with id 1  (this document is checked at startup to check the version field, if the new config has a new version, then we delete and re-index) 

(B) Locally or elsewhere: rake import_all checks DATA_VERSION env variable. If new config has a different version, then we index.  Issue [#50](https://github.com/18F/open-data-maker/issues/50) open to move these to the approach we're using in (A)
