nginx:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - require:
      - pkg: nginx
      - user: nginx
    - watch:
      - file: gitlab-nginx
  file.absent:
    - name: /etc/nginx/conf.d/default.conf
  user.present:
    - groups:
      - git
    - require:
      - pkg: nginx

{%- if salt['pillar.get']('gitlab:https', false) %}

gitlab-nginx:
  file.managed:
    - name: /etc/nginx/conf.d/gitlab.conf
    - source: salt://gitlab/files/gitlab-nginx-ssl
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

nginx-ssl-key:
  file.managed:
    - name: /etc/nginx/gitlab.key
    - user: root
    - group: nginx
    - mode: 640
    - contents_pillar: gitlab:ssl_key

nginx-ssl-cert:
  file.managed:
    - name: /etc/nginx/gitlab.crt
    - user: root
    - group: nginx
    - mode: 644
    - contents_pillar: gitlab:ssl_cert

{% else %}

gitlab-nginx:
  file.managed:
    - name: /etc/nginx/conf.d/gitlab.conf
    - source: salt://gitlab/files/gitlab-nginx
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx

{% endif %}

