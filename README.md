# BOINC Server for LODA

This repository contains the BOINC server for LODA. It is based on [boinc-server-docker](https://github.com/marius311/boinc-server-docker/).

## Installation

```bash
./start-server.sh
```

## Update Apps

Run on the code-signing machine:

```bash
git pull
./prepare-versions.sh
./sign-versions.sh
```

Copy the printed signature script.

Run on the server:

```bash
git pull
bash prepare-versions.sh
bash admin-shell.sh
cd

# Now paste the copied signature script!

cd $HOME/projects/loda
bin/update_versions

bin/start

# create initial work:
bin/create_work --appname loda --wu_name wu_loda input

# generate more work:
bin/make_work --wu_name wu_loda --one_pass
```

Add this line to index.php:

```html
Please make sure you have <code>git</code> installed.
```
