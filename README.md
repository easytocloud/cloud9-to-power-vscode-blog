## Use AWS Cloud9 to Power your Visual Studio Code IDE

The following repository contains the artifacts used in the blog post [Use AWS Cloud9 to Power your Visual Studio Code IDE](https://aws.amazon.com/blogs/architecture/field-notes-use-aws-cloud9-to-power-your-visual-studio-code-ide/).

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Changes

The original version of this code was a great inspriration for this fork. Why This fork? It

* fixes a bug or two
* automates some mandatory changes on the Cloud9 instance
* integrates the solution with easytocloud's aws-profile-organizer
* adds homebrew installation convenience

An other bug fix (not mine) is also available in an existing merge request on the original repo.
The other features are not so generic that many others would benefit.

Note, ssm-proxy is the original name, aws-proxy is the name used in this repo

## Installation instruction

The product has two components, one to run on your local device and one to run in the Cloud9 instance.

First install the local component. Once configured, connecting to the Cloud9 will make the necessary changes in your Cloud9 instance.

## local install

Install the local component using homebrew (assuming you have the easytocloud tap installed).
```
  $ brew install cloud9-to-power-vscode-blog
```
This installs two files in your /usr/local/bin.

### aws-proxy.sh

This shell-script will be used to connect to your Cloud9 instance and should be used in your ssh config (see example in config).
When connecting, ssm is used to run the cloud9-mod.json in your Cloud9 instance before actually connecting to the instance.

### cloud9-mod.json

This file is an SSM document, used to run code inside your Cloud9. 
The action performed is to replace the standard script that detects if your instance is active.
When the instance is (no longer) active, the instance will be suspended.

The standard script is not capable of detecting VSCode connections, the modified script created by this document fixes exactely that.
It keeps the previous version of the detection script and downloads a new one.
The script modified is called ~/.c9/stop-if-inactive.sh inside your Cloud9 instance.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
