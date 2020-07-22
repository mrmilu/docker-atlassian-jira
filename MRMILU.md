# Mr. Milú - Commands to publish version to docker-hub

```bash
$ docker login --username mrmilu
# $ docker login --username jhenjuto
$ docker build -t mrmilu/jira:8.11.0 .
$ docker push mrmilu/jira:8.11.0
```


## Jira version links
- https://marketplace.atlassian.com/apps/1213607/jira-software/version-history
- https://marketplace.atlassian.com/apps/1213632/jira-service-desk/version-history