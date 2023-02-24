#!/bin/bash

# More info:
# https://boinc.berkeley.edu/trac/wiki/CodeSigning
# https://boinc.berkeley.edu/trac/wiki/KeySetup
# https://boinc.berkeley.edu/trac/wiki/BuildSystem

set -e

pushd $HOME > /dev/null

if [ ! -f keys/code_sign_private ]; then
  mkdir -p keys
  echo "Keys not found. Please install or generate them using this command:"
  echo "crypt_prog -genkey 1024 $HOME/keys/code_sign_private $HOME/keys/code_sign_public"
  exit 1
fi

ADD_SIG=apps/add-sigs.sh

for f in $(find apps); do
  ext="${f##*.}"
  if [ -f $f ] && [ "$ext" != "sig" ] && [ ! -f "$f.sig" ] && [ $f != $ADD_SIG ]; then
    sign_executable "$f" keys/code_sign_private > $f.sig
  fi
done

echo "" > $ADD_SIG
for sig in $(find apps); do
  ext="${sig##*.}"
  if [ "$ext" = "sig" ]; then
    echo "cat << EOF > \$HOME/projects/loda/$sig" >> $ADD_SIG
    cat $sig >> $ADD_SIG
    echo "EOF" >> $ADD_SIG
    echo >> $ADD_SIG
  fi
done
echo "cat << EOF > \$HOME/projects/loda/keys/code_sign_public" >> $ADD_SIG
cat keys/code_sign_public >> $ADD_SIG
echo "EOF" >> $ADD_SIG
echo >> $ADD_SIG
echo "rm \$HOME/projects/loda/keys/code_sign_private 2> /dev/null" >> $ADD_SIG
echo >> $ADD_SIG
chmod oug+x $ADD_SIG

echo
echo "###### BEGIN SIGNATURES SCRIPT ######"
cat $ADD_SIG
echo "###### END SIGNATURES SCRIPT ######"
echo

popd > /dev/null
