# Taxonomy Parser

This is a sinatra app that parses static DTS assets and exposes their contents as a restful API.

DTS assets (Discoverable Taxonomy Set) are collections of xml files that together document financial systems in the XBRL language, e.g. UK, Irish, US GAAP or IFRS.

A client app would consume this api in order to facilitate tagging or validation of a set of financial statements.

You can find an example of a client app [here](//github.com/seocahill/dts-explorer-client).

## Included taxonomies

- UK 2012 GAAP
- Irish extension UK 2012 GAAP
- FRS 101 (planned)
- FRS 102 (planned)

To add another taxonomy simply place it in a new folder in the ```dts_assets``` directory.

To add an extension include the parent DTS within the extension's folder.

In theory the parsing rules should hold true for all DTS but in practice there are significant differences in how DTS are implemented apropos different reporting regimes - this is now being standardized in newer taxonomies.

## Jsonapi

The request / response data specification is jsonapi. 

[Go here](http://jsonapi.org/) for documentation on how to structure requests for resources.

The actual endpoints are defined in ```app.rb```.

## Running the server

```
docker-compose up
```

## Running the tests

```
docker-compose run api bundle exec rake test
```