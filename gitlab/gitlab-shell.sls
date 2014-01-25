gitlab-shell-git:
  git.latest:
    - name: https://gitlab.com/gitlab-org/gitlab-shell.git
    - rev: {{ salt['pillar.get']('gitlab:shell_version') }}
    - target: /home/git/gitlab-shell
    - user: git
    - require:
      - pkg: gitlab-deps
      - pkg: git
      - gem: bundler

gitlab-shell-config:
  file.managed:
    - name: /home/git/gitlab-shell/config.yml
    - source: salt://gitlab/files/gitlab-shell-config.yml
    - user: git
    - group: git
    - mode: 644
    - template: jinja
    - require:
      - git: gitlab-shell-git

gitlab-shell:
  cmd.wait:
    - user: git
    - cwd: /home/git/gitlab-shell
    - name: ./bin/install
    - watch:
      - git: gitlab-shell-git
    - require:
      - git: gitlab-shell-git
      - file: gitlab-shell-config
