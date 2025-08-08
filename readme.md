# docker-logseq-publish-spa

## The context : publishing information using logseq

- Logseq can be an easy/usefull way to publish information to a static site, especially when you're using git to backup your data : You can run the tool [logseq-publish-spa](https://github.com/logseq/publish-spa) to convert your logseq git repo to a static web site that act like a logsec read only acces application to your data, and then use a deployment tool to deploy it somewhere.
- It works nice when you sync you data with git and push it to github.
  - You can then use CI/CD integrated tools to do that
	- The tool logseq-publish-spa provide a logseq/publish-spa github action that works fine to produce html web site (CI)
	- You can then use github pages to deploy your static web site (CD)
  - Every time you push new data, after few minutes of CI/CD you can see your data in the github pages site.

## The problem

- This is totally fine for public web sites.
- The problem occurs when your web site should not be public : github only allow github page for public repo (for free account)
- The problem also occurs when your data can't be stored in github, not even in private repos (typically many work related content where data can only be synced on git repos inside corporate VPNn, and eveything outside is considered as a felony)

## The workaround

- public Gitlab instance ([gitlab.com](https://gitlab.com)) allow you to create (with free account) a private repo that deploy a static website in "Gitlab pages" that can be restricted to contributors of your private repo.
- Any private git server with integrated CI/CD (Whether it's [gitlab](https://gitlab.com), or [forgejo](https://forgejo.org/), or [Gitea](https://about.gitea.com/) or even [Gogs](https://gogs.io/)+external CI/CD) can be used work/very private context.
- But [logseq-publish-spa](https://github.com/logseq/publish-spa) appears to be quite complex to setup. Why isn't there a docker image that "just does that" ?

## The solution

- Well, now there is a docker image that "just does that".
- Source : https://github.com/gissehel/docker-logseq-publish-spa
- Docker image : **[ghcr.io/gissehel/logseq-publish-spa](https://github.com/gissehel/docker-logseq-publish-spa/pkgs/container/logseq-publish-spa)**
- Usage:
	- **Image name** : ghcr.io/gissehel/logseq-publish-spa:latest
	- Volumes :
		- /repo : The logseq folder (it should contains a folder named "assets", a folder named "journals", a folder named "logseq", and a folder named "pages".)
			- That folder can be mounted "ro", because nothing will be written in it
		- /export :The output folder. Should be an empty folder. An "index.html" will be generated inside it, and every files needed for you web site will be proced there.
- Example call:

```bash
$ mkdir -p /home/myuser/documents/logseq-html
$ docker run -ti --rm -v /repo:/home/myuser/documents/logseq-data:ro -v /export:/home/myuser/documents/logseq-html:rw ghcr.io/gissehel/logseq-publish-spa:latest
```

### Integration into gitlab-ci

- Let's suppose you've got a gitlab server (gitlab.com or private), a logseq repo you want to publish a gitlab repo. Let's suppose your logseq repo is a the top of your git repo (so the folders "assets", "journals", "logseq" and "pages" are directly at the root of your git repo)
- Just add a file **.gitlab-ci** at the top of your git repo with the following content:

```yaml
  pages:
    image: docker:latest
    services:
      - docker:dind
    stage: deploy
    variables:
      DOCKER_HOST: tcp://docker:2375/
      DOCKER_TLS_CERTDIR: ""
    script:
      - mkdir -p public
      - docker run --rm -v ${CI_PROJECT_DIR}:/repo:ro -v ${CI_PROJECT_DIR}/public:/export:rw ghcr.io/gissehel/logseq-publish-spa:latest
    artifacts:
      paths:
        - public
```

- **Note** : As for any html export, check that whether you added a `public:: true` at the top of all pages you want to export, or set "all pages should be public" in logseq (parameter `:publishing/all-pages-public? true` inside `/logseq/config.edn`) or else, no page will be published.
- **Note** : If your logseq data is not at the root of the git repo, but let's say in `/logseq-data`, just replace `${CI_PROJECT_DIR}:/repo:ro` by `${CI_PROJECT_DIR}/logseq-data:/repo:ro` in line 11 of the `.gitlab-ci` file.