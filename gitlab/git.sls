
{% if salt['pillar.get']('gitlab:proxy:enabled', false) %}
gitproxy:
  git.config:
    - name: http.proxy
    - value: {{ salt['pillar.get']('gitlab:proxy:address') }}
    - is_global: True
{% endif %}

