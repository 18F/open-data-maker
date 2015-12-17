# Dictionary Format

The data dictionary format may be (optionally) specified in the `data.yaml` file.  If unspecified, all columns are imported as strings.

## Simple Data Types

```
dictionary:
  name:
    source: COLUMN_NAME
    type: integer
    description: explanation of where this data comes from and its meaning
```

In the above example:
* `source:` is the name of the column in the csv. (This doesn't have to be all caps, we just find that to be common in government datasets.)
* `type:` may be `integer`,  `float`, `string`
* `description:` text description suitable for developer documentation or information provided to data analysts

## Calculated columns

Optionally, you can add "columns" by calculating fields at import based on multiple csv columns.  

```
academics.program.degree.health:
  calculate: CIP51ASSOC or CIP51BACHL
  type: integer
  description: Associate or Bachelor's degree in Health
```

Multiple operations are supported.  In the following example, if the columns `apples`, `oranges` and `plums` had a `0` value when there were none, and a `1` to represent if they were available, then these values could be combines with `or` to create a data field representing if any were true.

```
fruit:
  calculate: apples or oranges or plums
  type: integer
  description: is there any fruit available?
```
