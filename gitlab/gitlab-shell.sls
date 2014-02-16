include:
  - gitlab.user
  - gitlab.ruby

gitlab-shell-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-shell.git
    - rev: {{ salt['pillar.get']('gitlab:shell_version') }}
    - target: /home/git/gitlab-shell
    - user: git
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - sls: gitlab.ruby
      - file: git-home

# https://gitlab.com/gitlab-org/gitlab-shell/blob/master/config.yml.example
gitlab-shell-config:
  file.managed:
    - name: /home/git/gitlab-shell/config.yml
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
    - cwd: /home/git/gitlab-shell
    - name: ./bin/install
    - shell: /bin/bash
    - watch:
      - git: gitlab-shell-git
    - require:
      - file: gitlab-shell-config
