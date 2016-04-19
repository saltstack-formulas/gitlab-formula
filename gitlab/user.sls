{% set root_dir = salt['pillar.get']('gitlab:lookup:root_dir', '/home/git') %}

git-user:
  user.present:
    - name : git
    - system: True
    - shell: /bin/bash
    - fullname: GitLab
    - home: {{ root_dir }}

git-home:
  file.directory:
    - name: {{ root_dir }}
    - user: git
    - group: git
    - mode: 750
    - require:
      - user: git
