### To purge a cached asset from Squid

- On Squid Host:
`squidclient -m PURGE http://URL.of.Site/ABC.txt`

- From remote host:
`http_proxy=http://proxy.$DC.bbg:3128 curl -X PURGE http://URL.of.Site/ABC.txt`
