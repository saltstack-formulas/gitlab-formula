git-user:
  user.present:
    - name : git
    - system: True
    - shell: /bin/bash
    - fullname: GitLab
    - home: /home/git

git-home:
  file.directory:
    - name: /home/git
    - user: git
    - group: git
    - mode: 750
    - require:
      - user: git
