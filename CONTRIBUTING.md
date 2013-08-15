# Contributing to vim-mode

## Issues
  * Include the behavior you expected to happen
  * Check the Dev tools (`alt-cmd-i`) for errors and stack traces to
    include

## Testing

  * The jasmine tests must be run from within Atom, by running Atom in
    development mode and opening the spec window.
  * Pro-tip: place f in front of the test block you'd like to focus
    otherwise all of Atom's tests will run.

## Code
  * Follow the [JavaScript](https://github.com/styleguide/javascript) and
    [CSS](https://github.com/styleguide/css) styleguides
  * Include thoughtfully worded [Jasmine](http://pivotal.github.com/jasmine/)
    specs
  * Commit messages are capitalized and in the present tense
  * Files end with a newline
  * Class variables and methods should be in the following order:
    * Class variables (variables starting with a `@`)
    * Class methods (methods starting with a `@`)
    * Instance variables
    * Instance methods
