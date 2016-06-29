# Open Data Maker HTTP API

Open Data Maker exposes a read-only HTTP API for querying available datasets.
This document explains:
 * How to define and execute queries as URLs
 * Refining query results using option parameters
 * Extracting query results in JSON and CSV format
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
 * The **Format** for the result data. The default output format is JSON ([JavaScript Object Notation](http://json.org/)); CSV is
 also available.
 * The **Query String** containing a set of named key-value pairs that
 represent the query, which incude
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

Additionally, you can request `location.lat` and `location.lat` in a search that includes a `_fields` filter and it will return the record(s) with respective lat and/or lon coordinates.

#### Additional Notes on Geographic Filtering

* By default, any number passed in the `_distance` parameter is treated as a number of miles, but you can specify miles or kilometers by appending `mi` or `km` respectively.
* Distances are calculated from the center of the given zip code, not the boundary.
* Only U.S. zip codes are supported.
