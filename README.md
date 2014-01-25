gitlab-formula
==============

SaltStack formula to install GitLab

Salt state for installing GitLab - https://gitlab.com/gitlab-org/gitlab-ce

Initial work done for CentOS, heavily inspired by https://github.com/gitlabhq/gitlab-recipes/tree/master/install/centos

I'll try adding support for more systems with time.

I chose to use RVM for ruby because we'd need to compile ruby anyway, and this way is easy (easiest?) to do with salt.

I chose to use PostgreSQL "because".

I assume you're running gitlab under your node's FQDN, not under another name.
