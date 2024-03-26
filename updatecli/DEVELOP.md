To test the updatecli manifests locally:

```console
export UPDATECLI_GITHUB_TOKEN=<your token>
UPDATECLI_GITHUB_OWNER=<your user> updatecli diff --config updatecli/updatecli.d/update-deps.yaml --values updatecli/values.yaml
```
