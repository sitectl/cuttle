{% for backend in varnish.backends %}
backend {{ backend.name }} {
  .host = "{{ backend.host }}";
  .port = "{{ backend.port }}";
}
{% endfor %}

sub vcl_fetch {
  if (beresp.ttl <= 0s ||
      beresp.http.Set-Cookie ||
      beresp.http.Vary == "*") {
              /*
               * Mark as "Hit-For-Pass" for the next 10s
               */
              set beresp.ttl = 10 s;
              return (hit_for_pass);
  }
  set beresp.ttl = 6h;
  set beresp.grace = 12h;
  return (deliver);
}
