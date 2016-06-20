
{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{% set lib_dir = salt['pillar.get']('gitlab:lookup:lib_dir', root_dir ~ '/libraries') %}

{% set workhorse_dir = lib_dir ~ "/gitlab-workhorse" %}

{% if salt['pillar.get']('gitlab:archives:enabled', false) %}
    {% set workhorse_dir_content = workhorse_dir ~ '/' ~ salt['pillar.get']('gitlab:archives:sources:workhorse:content') %}
{% else %}
    {% set workhorse_dir_content = workhorse_dir %}
{% endif %}

gitlab-workhorse-fetcher:
{% if salt['pillar.get']('gitlab:archives:enabled', false) %}
  archive.extracted:
    - name: {{ workhorse_dir }}
    - source: {{ salt['pillar.get']('gitlab:archives:sources:workhorse:source') }}
    - source_hash: md5={{ salt['pillar.get']('gitlab:archives:sources:workhorse:md5') }}
    - archive_format: tar
    - if_missing: {{ workhorse_dir_content }}
    - keep: True
  file.directory:
    - name: {{ workhorse_dir }}
    - user: git
    - recurse:
      - user
{% else %}
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-workhorse.git
    - rev: {{ salt['pillar.get']('gitlab:workhorse_version') }}
    - target: {{ workhorse_dir }}
    - user: git
    - force: True
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home
{% endif %}

{{ root_dir }}/gitlab-workhorse:
  file.directory:
    - user: git
    - group: git
    - mode: 750

gitlab-workhorse-make:
  cmd.run:
    - user: git
    - cwd: {{ workhorse_dir_content }}
    - name: make install PREFIX={{ root_dir }}/gitlab-workhorse
    - shell: /bin/bash
    - onchanges:
    {% if salt['pillar.get']('gitlab:archives:enabled', false) %}
      - archive: gitlab-workhorse-fetcher
      - file: gitlab-workhorse-fetcher
    {% else %}
      - git: gitlab-workhorse-fetcher
    {% endif %}

