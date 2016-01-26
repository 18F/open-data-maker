# Open Data Maker HTTP API

Open Data Maker exposes a read-only HTTP API for querying available datasets.
This document explains:
 * How to define and execute queries as URLs
 * Refining query results using option parameters
 * Extracting query results in JSON and CSV format
 * Generating aggregate data using statistics queries
 * Detecting query errors

## Introduction to Queries

Each query is expressed as a URL, containing:

 * The **URL Path** to the Open Data Maker service, e.g.
 `https://collegescorecard.ed.gov/` (for Open Data Maker running its own
 server), or  `https://api.data.gov/ed/collegescorecard/v1/` (for Open
 Data Maker proxied through an API gateway)
 * The **API Version String**. Currently the only supported version string is: `v1`
 * The **Endpoint** representing a particular dataset, e.g. `schools`. Endpoint
 names are usually plural.
 * An optional **Query Type**, added to the Endpoint's path. Currently the only
 additional type is `stats`; see the section on [Statistics Queries](#statistics-queries) for more information.
 * The **Format** for the result data. The default output format is JSON ([JavaScript Object Notation](http://json.org/)); CSV is
 also available.
 * The **Query String** containing a set of named key-value pairs that
 represent the query, which include
   * **Field Parameters**, specifying a value (or set of values) to match
   against a particular field, and
   * **Option Parameters**, which affect the filtering and output of the
   entire query. Option Parameter names are prefixed with an underscore (`_`).

### Query Example

Here's an example query URL:

```
https://api.data.gov/ed/collegescorecard/v1/schools.json?school.degrees_awarded.predominant=2,3&_fields=id,school.name,2013.student.size
```

In this query URL:

 * `https://api.data.gov/ed/collegescorecard/v1/` is the URL Path.
 * `v1` is the API Version String, followed by `/`, which separates it from the Endpoint.
 * `schools` is the Endpoint. Note the plural.
 * `.json` is the Format. Note the dot between the Endpoint and Format. Also note that, since JSON is the default output format, we didn't _have_ to specify it.
 * In keeping with standard [URI Query String syntax](https://en.wikipedia.org/wiki/Query_string), the `?` and `&` characters are used to begin and separate the list of query parameters.
 * `school.degrees_awarded.predominant=2,3` is a Field Parameter. In this case, it's searching for records which have a `school.degrees_awarded.predominant` value of either `2` or `3`.
 * `_fields=id,school.name,2013.student.size` is an Option Parameter, as denoted by the initial underscore character. `_fields` is used to limit the output fields to those in the given list. We strongly recommend using the `_fields` parameter to reduce the amount of data returned by the API, thus increasing performance.

### JSON Output Example

Here's an example of the JSON document that Open Data Maker would provide
in response to the above query:

```json
{
  "metadata": {
    "total": 3667,
    "page": 0,
    "per_page": 20
  },
  "results": [
    {
      "id": 190752,
      "school.name": "Yeshiva of Far Rockaway Derech Ayson Rabbinical Seminary",
      "2013.student.size": 57
    },
    {
      "id": 407009,
      "school.name": "Arizona State University-West",
      "2013.student.size": 3243
    },
    {
      "id": 420574,
      "school.name":"Arizona State University-Polytechnic",
      "2013.student.size": 3305
    }

    // ... (further results removed) ...
  ]
}
```

A successful query will return a JSON with two top-level elements:

 * **`metadata`**: A JSON Object containing information about the results returned. The metadata fields are:
   * `total`: The total number of records matching the query
   * `page`: The page number for this result set
   * `per_page`: The number of records returned in a single result set. (For more information about the `page` and `per_page` fields, see the section on [Pagination](#pagination-with-_page-and-_per_page))
 * **`results`**: A JSON Array of record objects. Due to the use of the `_fields` option in this query, there are only three fields in each record - the three fields specified in the `_fields` parameter. When the `_fields` parameter is omitted, the full record is provided.

### Error Example

Let's change the query so as to generate an error when it's executed:

```
https://api.data.gov/ed/collegescorecard/v1/schools.json?school.degrees_awarded.predominant=frog&_fields=id,school.name,wombat
```

This is the JSON document returned:

```json
{
  "errors": [
    {
      "error": "field_not_found",
      "input": "wombat",
      "message": "The input field 'wombat' (in the fields parameter) is not a field in this dataset."
    },
    {
      "error": "parameter_type_error",
      "parameter": "school.degrees_awarded.predominant",
      "input": "frog",
      "expected_type": "integer",
      "input_type": "string",
      "message": "The parameter 'school.degrees_awarded.predominant' expects a value of type integer, but received 'frog' which is a value of type string."
    }
  ]
}
```

When failing to execute a query, Open Data Maker will attempt to return a JSON error document that explains the problem. Points to note:

 * The HTTP response status will be in the 400 or 500 range, indicating a problem.
 * The JSON document contains a single top-level element, `errors`, containing a JSON Array of error objects. Instead of simply returning the first error encountered, Open Data Maker attempts to list all the problems that it detected.
 * Error objects always contain these two elements:
   * `error`: a symbolic error code for the specific error that occurred.
   * `message`: an English description of the error.
 * Error objects may also contain these fields:
   * `input`: the provided input which triggered the error.
   * `parameter`: the parameter in which the `input` was supplied.
   * `input_type` & expected_type`: In the case of a type mismatch, these fields list the data types that were provided and expected.

## Field Parameters

Parameter names _without_ an underscore prefix are assumed to be field names in the dataset. Supplying a value to a field parameter acts as a query filter, and only returns records where the given field exactly matches the given value.

For example: Use the parameter `school.region_id=6` to only fetch records with a `school.region_id` value of `6`.

### Word and substring matches on `autocomplete` fields

Certain text fields in the dataset - those with the `autocomplete` data type - allow querying with a list of words. To search for a given word or string of words in those fields, just provide a list of space-separated words. This will return all records where the given field contains the given words as part of a string. **Note that all given words have to be at least three characters long.**

For example: To search for school names containing the words `New York`, use this parameter: `school.name=New%20York` (`%20` is a URL-encoded space) This will match all of these names:

* `New York College of Health Professions`
* `American Academy of Dramatic Arts-New York`
* `School of Professional Horticulture at the New York Botanical Garden`
* `The New College of York` (because the parameter words don't have to be found together)
* `Royal College of New Yorkminster` (because parameter words are matched as parts of other words)

but not this name:

* `New England School of Arts` (because `York` is missing)

### Value Lists

To filter by a set of strings or integers you can provide a comma-separated list of values. This will query the field for an exact match with _any_ of the supplied values.

For example: `school.degrees_awarded.predominant=2,3,4` will match records with a `school.degrees_awarded.predominant` value of `2`, `3` or `4`.

**Note:** Value lists with wildcards or floating-point numbers are not currently supported.

### Negative matches with the `__not` operator

To exclude a set of records from results, use a negative match (also known as an inverted match). Append the characters `__not` to the parameter name to specify a negative match.

For example: `school.region_id__not==5` matches on records where the `school.region_id` does _not_ equal `5`.

### Range matches with the `__range` operator

To match on field values in a particular numeric range, use a range match. Append the characters `__range` to the parameter name to specify a range match, and provide two numbers separated by two periods (`..`).

For example: `2013.student.size__range=100..500` matches on schools which had between 100 and 500 students in 2013.

Open-ended ranges can be performed by omitting one side of the range. For example: `2013.student.size__range=1000..` matches on schools which had over 1000 students.

You can even supply a list of ranges, separated by commas. For example, For example: `2013.student.size__range=..100,1000..2000,5000..` matches on schools which had under 100 students, between 1000 and 2000 students, or over 5000 students.

#### Additional Notes on Ranges

* Both integer and floating-point ranges are supported.
* The left-hand number in a range must be lower than the right-hand number.
* Ranges are inclusive. For example, the range `3..7` matches both `3` and `7`, as well as the numbers in between.

## Option Parameters

You can perform extra refinement and organisation of search results using **option parameters**. These special parameters have names beginning with an underscore character (`_`).

### Limiting Returned Fields with `_fields`

By default, records returned in the query response include all their stored fields. However, you can limit the fields returned with the `_fields` option parameter. This parameter takes a comma-separated list of field names. For example: `_fields=id,school.name,school.state` will return result records that only contain those three fields.

Requesting specific fields in the response will significantly improve performance and reduce JSON traffic, and is recommended.

### Pagination with `_page` and `_per_page`

By default, results are returned in pages of 20 records at a time. To retrieve pages after the first, set the `_page` option parameter to the number of the page you wish to retrieve. Page numbers start at zero; so, to return records 21 through 40, use `_page=1`. Remember that the total number of records available for a given query is given in the `total` field of the top-level `metadata` object.

You can also change the number of records returned per page using the `_per_page` option parameter, up to a maximum of 100 records. Bear in mind, however, that large result pages will increase the amount of JSON returned and reduce the performance of the API.

### Sorting with `_sort`

To sort results by a given field, use the `_sort` option parameter. For example, `_sort=population` will return records sorted by population size, in ascending order.

By default, using the `_sort_` option returns records sorted into ascending order, but you can specify ascending or descending order by appending `:asc` or `:desc` to the field name. For example: `_sort=population:desc`

**Note:** Sorting is only availble on fields with the data type `integer`, `float`, `autocomplete` or `name`.

### Geographic Filtering with `_zip` and `_distance`

When the dataset includes a `location` at the root level (`location.lat` and
`location.lon`) then the documents will be indexed geographically. You can use the `_zip` and `_distance` options to narrow query results down to those within a geographic area. For example, `_zip=12345&_distance=10mi` will return only those results within 10 miles of the center of the given zip code.

#### Additional Notes on Geographic Filtering

* By default, any number passed in the `_distance` parameter is treated as a number of miles, but you can specify miles or kilometers by appending `mi` or `km` respectively.
* Distances are calculated from the center of the given zip code, not the boundary.
* Only U.S. zip codes are supported.

## Statistics Queries

The queries discussed so far are only capable of returning individual records and selected values from those records. However, it's also possible to generate aggregate data from a specified set of records by making use of Statistics Queries.

### Statistics Query Example

Here's an example statistics query URL:

```
https://api.data.gov/ed/collegescorecard/v1/schools/stats?school.degrees_awarded.predominant=2,3&_fields=2013.student.size&_metrics=avg,sum,std_deviation,std_deviation_bounds
```

In this statistics query URL:

 * `/stats` is appended to the Endpoint. This is the key indicator that
 statistics should be returned instead of individual records.
 * `school.degrees_awarded.predominant=2,3` is a Field Parameter. In this case, it's searching for records which have a `school.degrees_awarded.predominant` value of either `2` or `3`. The aggregated statistics will be generated from this subset of records.
 * `_fields=2013.student.size` limits the aggregation to only operating over the `2013.student.size` field. Multiple fields can be specified and aggregated in a single query, but only those with numeric data can be used.
 * `_metrics` is an Option Parameter only available to statistics queries, and limits the kinds of aggregations performed. See below for more information.

This is the JSON document returned:

```json
{
  "metadata": {
    "total": 3667,
    "page": 0,
    "per_page": 20
  },
  "results": [],
  "aggregations": {
    "school.tuition_revenue_per_fte": {
      "avg": "0.1088815711947627E5",
      "sum": 73288234,
      "std_deviation": "0.75913587304684015E4",
      "std_deviation_bounds": {
        "upper": "0.26070874580413074E5",
        "lower": "-0.4294560341460534E4"
      }
    }
  }
}
```

Note that the top-level elements returned by a statistics query differ from those returned by other kinds of queries:

  * **`metadata`** provides the same information as it does in other queries.
    * **`total`** provides the number of records matching the query (in this case, all those schools with a `school.degrees_awarded.predominant` of 2 or 3). This is the subset of records from which the statistics are calculated.
    * **`page`** and **`per_page`** are irrelevant in statistics queries, and will likely be removed in a future version of the API.
  * **`results`** is always empty in statistics queries, and may be removed in a future version of the API.
  * **`aggregations`** contains a JSON Object for every field specified in the `_fields` parameter. Within these Objects there's an entry for every type of aggregation performed. In this case, use of the `_metrics` parameter has limited the returned aggregations to `avg`, `sum`, `std_deviation` and `std_deviation_bounds`. See below for more information.

### Specifying aggregations with `_metrics`

By default, the full set of available aggregations is calculated and returned for each field specified in the `_fields` parameter. These aggregations are calculated by ElasticSearch's [Extended Stats Aggregation](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/search-aggregations-metrics-extendedstats-aggregation.html):

 * `count`
 * `min`
 * `max`
 * `avg`
 * `sum`
 * `sum_of_squares`
 * `variance`
 * `std_deviation`
 * `std_deviation_bounds`

Each of these provides a single value, with the expection of `std_deviation_bounds`, which provides a JSON Object containing `upper` and `lower` bounds.
