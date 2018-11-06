{% if grains['os_family'] == 'Debian' %}
{% set nginx_user = 'www-data' %}
{% set nginx_path = '/etc/nginx/sites-enabled' %}
{% elif grains['os_family'] == 'RedHat' %}
{% set nginx_user = 'nginx' %}
{% set nginx_path = '/etc/nginx/conf.d' %}
{% endif %}

install_nginx_gitlab:
  pkg.installed: 
    - name: nginx

ensure_nginx_service_running:
  service.running:
    - enable: True
    - require:
      - pkg: nginx
      - user: nginx
    - watch:
      - file: gitlab-nginx
  
Remove_default_nginx_file:  
  file.absent:
    - name: {{ nginx_path }}/default.conf
  
Create_nginx_user:  
  user.present:
    - name: {{ nginx_user }}
    - groups:
      - git
    - require:
      - pkg: nginx

{%- if salt['pillar.get']('gitlab:https', false) %}

# https://gitlab.com/gitlab-org/gitlab-recipes/blob/master/web-server/nginx/gitlab-ssl
gitlab-nginx:
  file.managed:
    - name: {{ nginx_path }}/gitlab.conf
    - source: salt://gitlab/files/gitlab-nginx-ssl
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx
      - file: nginx-ssl-key
      - file: nginx-ssl-cert

nginx-ssl-key:
  file.managed:
    - name: /etc/nginx/gitlab.key
    - user: root
    - group: {{ nginx_user }}
    - mode: 640
    - contents_pillar: gitlab:ssl_key
    - watch_in:
      - service: nginx

nginx-ssl-cert:
  file.managed:
    - name: /etc/nginx/gitlab.crt
    - user: root
    - group: {{ nginx_user }}
    - mode: 644
    - contents_pillar: gitlab:ssl_cert
    - watch_in:
      - service: nginx

{% else %}

# https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/support/nginx/gitlab
gitlab-nginx:
  file.managed:
    - name: {{ nginx_path }}/gitlab.conf
    - source: salt://gitlab/files/gitlab-nginx
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

{% endif %}

