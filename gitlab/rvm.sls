ruby-2.1.0:
  rvm.installed:
    - default: True
    - user: git
    - require:
      - user: git-user
      - pkg: rvm-deps

bundler:
  gem.installed:
    - user: git
    - ruby: ruby-2.1.0
    - require:
      - rvm: ruby-2.1.0
