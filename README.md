# slimane-github-issue-manager

Sample application with [Slimane](https://github.com/noppoMan/Slimane)  
This was a Demo App used in [Tokyo Server Side Meetup vol.3](http://tokyo-ss-swift.connpass.com/event/30823/)

## Getting Started

### Requirements
* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)

First, Need to install requirements to your machine.

### Boot your Linux
```sh
$ vagrant up
$ vagrant ssh
```

### Launch Slimane App
```
$ sudo su -
$ cd slimane-github-issue-manager
$ .build/debug/GithubIssueManager
Listening slimane http server at 0.0.0.0:3000
```

### Check in the Browser
Access `http://localhost:3000`

### Update own and dependencies
```sh
git pull origin master
make clean
make debug
```

