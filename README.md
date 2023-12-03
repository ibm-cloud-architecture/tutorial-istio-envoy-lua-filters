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
```bash
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
    "locale": "us",
  },
  "method": "GET",
  "body": "",
  "protocol": "http",
  "query": {
    "locale": "us"
  },
}
```

### Example 2: Load external lua library
[example-2-lib](./example-2-lib)

Loads the library [./example-2-lib/uuid.lua](./example-2-lib/uuid.lua)

Adds a header with a random uuid if the header is not already present in the request

Send the request
```bash
curl "localhost:8000/api/v1"
```

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
```bash
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

### Example 4: Full Example
[example-4-full](./example-4-full)

Full complex example parsing headers, query, body, and generating uuid

Loads the libraries:
- [./example-2-lib/uuid.lua](./example-2-lib/uuid.lua)
- [./example-3-json/JSON.lua](./example-3-json/JSON.lua)


Detects if any of the headers (`locale`,`brand`,`systemid`,`correlationid`) are missing, tries to add the header with the value from query parameter or body json.

If correlationid is not present at all then a new value is generated using a random uuid.

Send the request POST with an `application/json` body:
```bash
curl -d '{"systemid":"FFEE"}' \
-H "Content-Type:application/json" \
"http://localhost:8000/api/v1?brand=acme&locale=en-us"
```

The request will include all the missing headers going from the proxy to the web service.
```json
{
"locale": "en-us",
"brand": "acme",
"systemid": "FFEE",
"correlationid": "GEN-cbb297c0-14a9-46bc-c691-1d0ef9b42df9"
}
```
Full request echo back from web service:
```json
{
  "path": "/api/v1",
  "headers": {
    "host": "localhost:8000",
    "user-agent": "curl/7.54.0",
    "accept": "*/*",
    "content-type": "application/json",
    "content-length": "19",
    "locale": "en-us",
    "brand": "acme",
    "systemid": "FFEE",
    "correlationid": "GEN-cbb297c0-14a9-46bc-c691-1d0ef9b42df9",
  },
  "method": "POST",
  "body": "{\"systemid\":\"FFEE\"}",
  "protocol": "http",
  "query": {
    "brand": "acme",
    "locale": "en-us"
  },
}
```

### Example 5: Kubernetes Example
[example-5-kubernetes](./example-5-kubernetes)

This example shows how to store the lua files in a ConfigMap, then mounting in envoy container

Deploy config-map, deployment, and services
```bash
cd example-5-kubernetes/
kubectl apply -k .
```

Open a port forward to reach the envoy provice service
```bash
kubectl port-forward service/envoy-service 8000:80
```

Now send a request similar as example 4:
```bash
curl -d '{"systemid":"FFEE"}' \
-H "Content-Type:application/json" \
"http://localhost:8000/api/v1?brand=acme&locale=en-us"
```

### Example 6: Istio Example
[example-6-istio](./example-6-istio)

This example shows how to store the lua files in a ConfigMap, then mounting in envoy container

Deploy config-map, deployment, and services
```bash
cd example-6-istio/
kubectl apply -f .
```

Update the deployment `istio-ingressgateway` to add the lua files
```
kubectl edit deployment istio-ingressgateway -n istio-system
```
Add the volumeMounts in the corresponding section in the container `proxy`
```yaml
volumeMounts:
- mountPath: /var/lib/lua
  name: config-volume-lua
```
Add the volume in the corresponding section in the container `proxy`
```yaml
volumes:
- name: config-volume-lua
  configMap:
    name: lua-libs
    items:
    - key: JSON.lua
      path: JSON.lua
    - key: uuid.lua
      path: uuid.lua
```

Open a port forward to reach the `istio-ingressgateway`
```bash
kubectl port-forward service/istio-ingressgateway 8000:80 -n istio-system
```

Now send a request similar as example 4:
```bash
curl -v -d '{"systemid":"FFEE"}' \
-H "Content-Type:application/json" \
"http://localhost:8000/api/v1?brand=acme&locale=en-us"
```
