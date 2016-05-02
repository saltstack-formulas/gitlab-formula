
{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{% set lib_dir = salt['pillar.get']('gitlab:lookup:lib_dir', root_dir ~ '/libraries') %}

{% if salt['pillar.get']('gitlab:proxy:enabled', false) %}
gitlab-workhorse-git-present:
  git.present:
    - name: {{ lib_dir }}/gitlab-workhorse.git
    - bare: False

gitlab-workhorse-git-proxy:
  git.config:
    - name: http.proxy
    - value: {{ salt['pillar.get']('gitlab:proxy:address') }}
    - repo: {{ lib_dir }}/gitlab-workhorse.git
{% endif %}

gitlab-workhorse-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-workhorse.git
    - rev: {{ salt['pillar.get']('gitlab:workhorse_version') }}
    - target: {{ lib_dir }}/gitlab-workhorse.git
    - user: git
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home
      {% if salt['pillar.get']('gitlab:proxy:enabled', false) %}
      - git: gitlab-workhorse-git-proxy
      {% endif %}

{{ root_dir }}/gitlab-workhorse:
  file.directory:
    - user: git
    - group: git
    - mode: 750

gitlab-workhorse-make:
  cmd.run:
    - user: git
    - cwd: {{ lib_dir }}/gitlab-workhorse.git
    - name: make install PREFIX={{ root_dir }}/gitlab-workhorse
    - shell: /bin/bash
    - require:
      - git: gitlab-workhorse-git
      - file: {{ root_dir }}/gitlab-workhorse

