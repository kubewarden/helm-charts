# Contributing: this is only an automation repo

> [!IMPORTANT] > **Notice:**
> Starting from Kubewarden release 1.32.0, we moved the Helm charts code for
> the Adm Controller to a monorepo at [github.com/kubewarden/kubewarden-controller](https://github.com/kubewarden/kubewarden-controller).
> The source of truth for the Helm charts is at the different component
> repositories such as that one, and not under this repository.
>
> If you intend to contribute, you probably should submit your contributions there
> instead against this repo.
>
> This repository is used for CI and aggregator of several Helm charts that are part
> of the Kubewarden project.

# Releasing

Workflow:

1. Perform a the intended release of whatever component in their repository, for example kubewarden/kubewarden-controller.
   This triggers the update-charts.yml workflow in kubewarden/helm-charts.
1. The update-charts.yml workflow in kubewarden/helm-charts succeeds, which
   opens a PR against this repo to review.
1. The PR doesn't trigger CI (see [here](https://github.com/kubewarden/helm-charts/issues/324)).
   Workaround: close the PR and immediately open it.
1. Review the PR. Note that you should review the changes since the last
   available release of the charts up until the PR contents, but not only the
   PR contents.
   And easy way to do that is to do a compare between the last tag and the
   branch of the PR (see this [example](https://github.com/kubewarden/helm-charts/compare/kubewarden-defaults-1.7.3...updatecli_9cdd3756d921d5ada8a9fcc0ef40ad745a44079a53c2b4c0bdaf0e307eceb4b9)).
1. Merge the PR. This triggers release-drafter
1. Check that the charts are generally available.
1. Check that https://github.com/kubewarden/helm-charts/releases is correct.
1. Create new versioned docs as needed, by merging the automated PR against
   kubewarden/docs, and triggering Algolia's crawler.

## Helm chart repo automation

Releases of the helm-charts are automated via the helm-chart-release workflow,
using chart-releaser. Once a chart with a bumped `version` arrives in `main`,
it will get consumed by chart-releaser, which takes care of building the chart
and publishing it to the gh-pages branch.

## Helm chart contents automation

The repo also has automation for the contents of the helm chart
themselves.bumping the charts, by consuming container images and other assets
such as CRDs, and making diffs with updatecli.

It may happen that several workflow dispatches get triggered against
kubewarden/helm-charts repo. The dispatches may happen before GH has made the
GH release assets public. For example, the dispatch from
kubewarden/kubewarden-controller may trigger a new "Update charts" job in
kubewarden/helm-charts, and, the GH Relase page for the controller may be
showing the correct assets, but the helm-charts workflow may have not yet seen
the changes (because of caching, etc).

This issue can happen for several dispatches, as one normally tags the
container images in succession.

### Workaround

The easy workaround is to wait some minutes for the dust to settle, and
retrigger all the jobs. There will be one that is successful, and will open a
PR against kubewarden/helm-charts for review.
