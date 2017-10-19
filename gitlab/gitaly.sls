{%- set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{%- set repositories = salt['pillar.get']('gitlab:lookup:repositories', root_dir ~ '/repositories') %}
{%- set sockets_dir = salt['pillar.get']('gitlab:lookup:sockets_dir', root_dir ~ '/var/sockets') %}
{%- set lib_dir = salt['pillar.get']('gitlab:lookup:lib_dir', root_dir ~ '/libraries') %}

{%- set gitaly_dir = lib_dir ~ "/gitaly" %}

{%- if salt['pillar.get']('gitlab:archives:enabled', false) %}
    {%- set gitaly_dir_content = gitaly_dir ~ '/' ~ salt['pillar.get']('gitlab:archives:sources:gitaly:content') %}
{%- else %}
    {%- set gitaly_dir_content = gitaly_dir %}
{%- endif %}

{%- if salt['pillar.get']('gitlab:archives:enabled', false) %}
gitaly-fetcher:
  archive.extracted:
    - name: {{ gitaly_dir }}
    - source: {{ salt['pillar.get']('gitlab:archives:sources:gitaly:source') }}
    - source_hash: md5={{ salt['pillar.get']('gitlab:archives:sources:gitaly:md5') }}
    - archive_format: tar
    - if_missing: {{ gitaly_dir_content }}
    - keep: True

gitaly-chown:
  file.directory:
    - name: {{ gitaly_dir }}
    - user: git
    - group: git
    - recurse:
      - user
    - onchanges:
      - archive: gitaly-fetcher
{%- else %}
gitaly-fetcher:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitaly.git
    - rev: {{ salt['pillar.get']('gitlab:gitaly_version') }}
    - target: {{ gitaly_dir_content }}
    - user: git
    - force: True
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home
{%- endif %}

gitaly-private-sockets-dir:
  file.directory:
    - name: {{ sockets_dir }}/private
    - user: git
    - group: git
    - mode: 700

gitaly-bin-dir:
  file.directory:
    - name: {{ root_dir }}/gitaly
    - user: git
    - group: git
    - mode: 750

gitaly-make:
  cmd.run:
    - name: make build install DESTDIR={{ root_dir }}/gitaly PREFIX=
    - user: git
    - cwd: {{ gitaly_dir_content }}
    - env:
      {%- if salt['pillar.get']('gitlab:proxy:address') %}
      - HTTP_PROXY: {{ pillar.gitlab.proxy.address }}
      - HTTPS_PROXY: {{ pillar.gitlab.proxy.address }}
      {%- endif %}
    - onchanges:
      - gitaly-fetcher
    - require:
      - file: gitaly-bin-dir

# https://gitlab.com/gitlab-org/gitaly/blob/master/config.toml.example
# gitaly looks for configuration in the same directory it is running from
gitaly-config:
  file.managed:
    - name: {{ root_dir }}/gitaly/bin/config.toml
    - source: salt://gitlab/files/gitaly-config.toml
    - template: jinja
    - user: git
    - group: git
    - mode: 644
    - context:
        root_dir: {{ root_dir }}
        sockets_dir: {{ sockets_dir }}
        repositories: {{ repositories }}
        gitaly_dir_content: {{ gitaly_dir_content }}
    - require:
      - gitaly-fetcher
      - file: gitaly-bin-dir
      - cmd: gitaly-make
