include:
  - gitlab.user
  - gitlab.ruby

{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}
{% set lib_dir = salt['pillar.get']('gitlab:lookup:lib_dir', root_dir ~ '/libraries') %}

gitlab-shell-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-shell.git
    - rev: {{ salt['pillar.get']('gitlab:shell_version') }}
    - target: {{ lib_dir }}/gitlab-shell.git
    - user: git
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home

# https://gitlab.com/gitlab-org/gitlab-shell/blob/master/config.yml.example
gitlab-shell-config:
  file.managed:
    - name: {{ lib_dir }}/gitlab-shell.git/config.yml
    - source: salt://gitlab/files/gitlab-shell-config.yml
    - template: jinja
    - user: git
    - group: git
    - mode: 644
    - require:
      - git: gitlab-shell-git

gitlab-shell:
  cmd.wait:
    - user: git
    - cwd: {{ lib_dir }}/gitlab-shell.git
    - name: ./bin/install
    - shell: /bin/bash
    - watch:
      - git: gitlab-shell-git
    - require:
      - file: gitlab-shell-config

gitlab-shell-chmod-bin:
  file.directory:
    - name: {{ lib_dir }}/gitlab-shell.git/bin
    - file_mode: 0770
    - recurse:
      - mode

