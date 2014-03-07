## Maintainers Guide

We'd like to foster an active community of mutual respect. With that as our
guiding principle, we strive to do the following:

* Respond to issues/pulls in a timely manner.
* Encourage new contributors when possible.
* Maintain high code quality by ensuring all pull requests:
  * Have clear concise code.
  * Have passing specs.
  * Have a proper note in the docs (if appropriate).
  * Be made mergable by its creator (good feedback is hard enough).
  * If a pull doesn't meet these standards, we should offer helpful actionable
    advice to get it there.
* Add `CHANGELOG.md` entries for every pull merged.
* Publish new releases in a timely manner.
* Responsibly upgrade along with Atom core
  * Tag the last compatible version with the correct Atom version before making a breaking change
  * Merge finished pull requests before merging breaking changes
* Label issues clearly
  * As either an `issue`, `enhancement` or `question`.
  * The `question` label indicates that there's a question about current
    functionality or future functionality.
* Label pull requests clearly
  * As either an `issue` or `enhancement`.
  * While being reviewed mark an additional `under-review` label if appropriate,
    so the community knows the status.
  * If a pull request requires changes by the creator an additional
    `requires-changes` label is appropriate.
  * Pulls that require core changes that aren't ready yet should be labeled
    with an additional `blocked` label.
