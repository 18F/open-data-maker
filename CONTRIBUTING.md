## Contributing

We aspire to create a welcoming environment for collaboration on this project.
To that end, we follow the [18F Code of Conduct](https://github.com/18F/code-of-conduct/blob/master/code-of-conduct.md) and ask that all contributors do the same.

### Public domain

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.

## Communication

There are a few ways to communicate with other folks working on this project:

* For general questions, discussion and announcements, please join [Google Group]
* For noisy, informal chatter, you can join us on the [open-data-maker-pub Slack Channel](https://chat.18f.gov).  Notifications from github are posted here.
* For bug reports, please [file an issue](https://github.com/18F/open-data-maker/issues).

## About the Tech

This is a web app, written in Ruby, with Elasticsearch.

Key Dependencies:

* [Padrino](http://www.padrinorb.com/) - Ruby Web framework based on Sinatra
* [Liquid](http://liquidmarkup.org/) view templates
* [Elastic Search](https://www.elastic.co)


## Development Process

Fork the project and follow the instructions in the [Installation Guide](INSTALL.md) to set up your development environment.

All the tests should pass and new functionality or bug fixes should have a new
test before submitting a pull request.

The default branch is 'dev'.  All changes should be submitted as pull requests
on the dev branch with a branch named dev-something (except for critical, urgent fixes, which may be branched off master or staging).

This project follows the [git flow](http://nvie.com/posts/a-successful-git-branching-model/) branching model of product development.  After we do integrated testing in dev, we merge to staging
for review by our design and product folks, then to master.  

This project is in alpha, so things are fast moving! We hope you consider it
a fun time to get involved.  In the near term, we have a very specific focus for this app, but we expect it will be generally useful for other projects as well.  If you are thinking about deploying this app at your agency or organization, please let us know by introducing yourself in the [Google Group] and telling us a bit about your project or idea. 

### Testing

For testing, we are using [rspec](http://rspec.info/).

To run all the tests:

```rake spec```


### <a name="commit-messages"></a> Commit Messages

Treat commit messages as an email message that describes what you changed and why.

The first line of the commit log must be treated as as an email
subject line.  It must be strictly no greater than 50 characters long.
The subject must stand on its own and not only make external
references such as to relevant bug numbers.

The second line must be blank.

The third line begins the body of the commit message (one or more
paragraphs) describing the details of the commit.  Paragraphs are each
separated by a blank line.  Paragraphs must be word wrapped to be no
longer than 76 characters.  

The last part of the commit log should contain all "external
references", such as which issues were fixed. Please reference the github issue number.

## <a name="submit"></a> Submission Guidelines

### Submitting an Issue
Before you submit your issue search the archive, maybe your question was already answered.

If your issue appears to be a bug, and hasn't been reported, open a new issue.
Help us to maximize the effort we can spend fixing issues and adding new
features, by not reporting duplicate issues.  Providing the following information will increase the
chances of your issue being dealt with quickly:

* **Overview of the issue** - if an error is being thrown a non-minified stack trace helps
* **Motivation for or Use Case** - explain why this is a bug for you
* **Version(s)** - is it a regression?
* **Browsers and Operating System** - is this a problem with all browsers or only IE8?
* **Reproduce the error** - provide a live example, screenshot, and/or a unambiguous set of steps. The more the better.
* **Related issues** - has a similar issue been reported before?  Reference the related issues in the descrioption.
* **Suggest a Fix** - if you can't fix the bug yourself, perhaps you can point to what might be
  causing the problem (line of code or commit).  If you're requesting a feature, describe how the feature might work to resolve the user story.

### Submitting a Pull Request
Before you submit your pull request consider the following guidelines:

* Search [GitHub](https://github.com/18F/open-data-maker/pulls) for an open or closed Pull Request that relates to your submission. You don't want to duplicate effort.
* Make your changes in a new git branch

     ```shell
     git checkout -b my-fix-branch master
     ```

* Create your patch, **including appropriate test cases**.
* Run the full test suite ```rake spec``` and ensure that all tests pass.
* Commit your changes using a descriptive commit message that follows our
  [commit message conventions](#commit-messages). Adherence to the [commit message conventions](#commit-messages)
  is required to assist in generating release notes.

     ```shell
     git commit -a
     ```
  Note: the optional commit `-a` command line option will automatically "add" and "rm" edited files.

* Push your branch to GitHub:

    ```shell
    git push origin my-fix-branch
    ```

* In GitHub, send a pull request to `open-data-maker:dev`.
* If we suggest changes then:
  * Make the required updates.
  * Re-run the  test suite to ensure tests are still passing.
  * Rebase your branch and force push to your GitHub repository (this will update your Pull Request):

    ```shell
    git rebase dev -i
    git push -f
    ```

That's it! Thank you for your contribution!

#### After your pull request is merged

After your pull request is merged, you can safely delete your branch and pull the changes from the main (upstream) repository:

* Check out the dev branch:

    ```shell
    git checkout dev -f
    ```

* Delete the local branch:

    ```shell
    git branch -D dev-my-fix
    ```

* Update with the latest upstream version:

    ```shell
    git pull --ff upstream dev
    ```
  Note: this assumes that you have already added the `upstream` remote repository, using this command:

    ```shell
    git remote add upstream https://github.com/18F/open-data-maker.git
    ```


* For folks with write access to the repo: delete the remote branch on GitHub either through the GitHub web UI or your local shell as follows:

    ```shell
    git push origin --dev-my-fix
    ```

### Reviewing Pull Requests

We often have only one developer working on this project, so we will frequently
merge pull requests without peer review.  However, all commits should happen
via pull request, and a great way to contribute is to take a look at the open
pull requests and review or comment.  In the near term, we're focused on a
specific use case, so we won't necessarily address every comment, but it is
always great to see feedback.

Anyone who reviews a pull request should leave a note to let others know that
someone has looked at it. For larger commits, we like to have a +1 from someone
else on the core team and/or from other contributor(s). Please note if you
reviewed the code or tested locally -- a +1 by itself will typically be
interpreted as your thinking its a good idea, but not having reviewed in detail.

[Google Group]: https://groups.google.com/d/forum/open-data-maker
