gitlab-db:
  postgres_user.present:
    - name: {{ salt['pillar.get']('gitlab:db_user') }}
    - password: {{ salt['pillar.get']('gitlab:db_pass') }}
  postgres_database.present:
    - name: {{ salt['pillar.get']('gitlab:db_name') }}
    - owner: {{ salt['pillar.get']('gitlab:db_user') }}
    - template: template1
    - require:
      - postgres_user: gitlab-db
