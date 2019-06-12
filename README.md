In this example, we show how a Lua filter can be used with the Envoy
proxy. The Envoy proxy [configuration](./envoy.yaml) includes a lua
filter that contains two functions namely
`envoy_on_request(request_handle)` and
`envoy_on_response(response_handle)` as documented
[here](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/lua_filter).



# Usage
1. `docker-compose pull`
2. `docker-compose up --build`
3. `curl -v localhost:8000`

## Sample Output:

Curl output should include our headers:

```
# <b> curl -v localhost:8000</b>
* Rebuilt URL to: localhost:8000/
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET / HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.47.0
> Accept: */*
>
< HTTP/1.1 200 OK
< x-powered-by: Express
< content-type: application/json; charset=utf-8
< content-length: 544
< etag: W/"220-PQ/ZOdrX2lwANTIy144XG4sc/sw"
< date: Thu, 31 May 2018 15:29:56 GMT
< x-envoy-upstream-service-time: 2
< response-body-size: 544            <-- This is added to the response header by our Lua script. --<
< server: envoy
<
```
```json
{
  "path": "/",
  "headers": {
    "host": "localhost:8000",
    "user-agent": "curl/7.47.0",
    "accept": "*/*",
    "x-forwarded-proto": "http",
    "x-request-id": "0adbf0d3-8dfd-452f-a80a-1d6aa2ab06e2",
    "foo": "bar",                    <-- This is added to the request header by our Lua script. --<
    "x-envoy-expected-rq-timeout-ms": "15000",
    "content-length": "0"
  },
  "method": "GET",
  "body": "",
  "fresh": false,
  "hostname": "localhost",
  "ip": "::ffff:172.18.0.2",
  "ips": [],
  "protocol": "http",
  "query": {},
  "subdomains": [],
  "xhr": false,
  "os": {
    "hostname": "5ad758105577"
  }
```
```
* Connection #0 to host localhost left intact
}
```

## Additional Examples

To run the examples change directory and run normal docker-compose up/down assuming you already pull and build

Run the example 1:
```
cd example-1-query
docker-compose up
```

### Example 1: Query Param
[example-1-query](./example-1-query)

Parse a query parameter and add the value as a header into the request

Send the request `curl "localhost:8000/api?locale=us"`

The value `us` is included in the request header `locale` going out from the proxy to the web service
```json
{
  "path": "/api",
  "headers": {
    "host": "localhost:8000",
    "user-agent": "curl/7.54.0",
    "locale": "pr",
  },
  "method": "GET",
  "body": "",
  "protocol": "http",
  "query": {
    "locale": "pr"
  },
}
```

### Example 2: Load external lua library
[example-2-lib](./example-2-lib)

Loads the library [./example-2-lib/uuid.lua](./example-2-lib/uuid.lua)

Adds a header with a random uuid if the header is not already present in the request

Send the request `curl "localhost:8000/api/v1"`

The random uuid is included in the request header `correlationid` going out from the proxy to the web service
```json
{
  "path": "/api",
  "headers": {
    "host": "localhost:8000",
    "user-agent": "curl/7.54.0",
    "correlationid": "GEN-cbb297c0-14a9-46bc-c691-1d0ef9b42df9"
  },
  "method": "GET",
  "body": "",
  "protocol": "http"
}
```

### Example 3: Parse body JSON
[example-3-json](./example-3-json)

Loads the library [./example-3-json/JSON.lua](./example-3-json/JSON.lua)

Adds a header using the value from the body if the header is not already present in the request.

Send the request POST with an `application/json` body:
```
curl -d '{"correlationid":"GEN-00000000-1111-2222-3333-444444444444"}' \
-H "Content-Type:application/json" \
http://localhost:8000
```

The value from the body field `correlationid` is included in the request header `correlationid` going out from the proxy to the web service
```json
{
  "path": "/",
  "headers": {
    "host": "localhost:8000",
    "user-agent": "curl/7.54.0",
    "accept": "*/*",
    "content-type": "application/json",
    "content-length": "60",
    "correlationid": "GEN-00000000-1111-2222-3333-444444444444"
  },
  "method": "POST",
  "body": "{\"correlationid\":\"GEN-00000000-1111-2222-3333-444444444444\"}",
  "protocol": "http",
}
```

