include:
  - gitlab.user
  - gitlab.ruby

{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}

gitlab-shell-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-shell.git
    - rev: {{ salt['pillar.get']('gitlab:shell_version') }}
    - target: {{ root_dir }}/gitlab-shell
    - user: git
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home

# https://gitlab.com/gitlab-org/gitlab-shell/blob/master/config.yml.example
gitlab-shell-config:
  file.managed:
    - name: {{ root_dir }}/gitlab-shell/config.yml
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
    - cwd: {{ root_dir }}/gitlab-shell
    - name: ./bin/install
    - shell: /bin/bash
    - watch:
      - git: gitlab-shell-git
    - require:
      - file: gitlab-shell-config
