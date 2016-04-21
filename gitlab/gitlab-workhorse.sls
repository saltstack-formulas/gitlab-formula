
{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{% set lib_dir = salt['pillar.get']('gitlab:lookup:lib_dir', root_dir ~ '/libraries') %}

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

