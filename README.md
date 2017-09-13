# taxonomy-parser

This is a sinatra app for parsing XBRL discoverable taxonomy sets and exposing endpoints to query the data.

## Resources

- Discoverable taxonomy Sets (e.g "uk-gaap-2012-12-01")
- Role types (e.g. "Entity information")
- Elements (e.g. "uk-gaap_NameEntityOfficer")
- Presentation nodes (nodes on the presentation tree that point to an element)
- Dimension nodes (nodes on the dimensional trees that point to an element)
- Labels (An element may have many e.g. standard or label)
- References (An element may have many e.g. section, paragraph)

## Jsonapi

The request / response data specification is jsonapi. 

[Go here](http://jsonapi.org/) for documentation on how to structure requests for resources.

The actual endpoints are defined in ```app.rb```.