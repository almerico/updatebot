#!/usr/bin/env bash
set -e

# ensure we're not on a detached head
git checkout master

# until we switch to the new kubernetes / jenkins credential implementation use git credentials store
git config credential.helper store
jx step git credentials

# display the current namespace
jx ns -b

mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
jx step gpg credentials -o ~/.gnupg
chmod 600 ~/.gnupg/*

export GPG_TTY=/dev/tty

export VERSION="$(jx-release-version)"
echo "Setting the maven version to ${VERSION}"

mvn versions:set -DnewVersion=${VERSION}

mvn clean -B
mvn -V -B -e -U install org.sonatype.plugins:nexus-staging-maven-plugin:1.6.7:deploy -P release -P openshift -DnexusUrl=https://oss.sonatype.org -DserverId=oss-sonatype-staging

# now release the sonatype staging repo
jx step nexus release
jx step tag --version ${VERSION}

updatebot push-version --kind docker UPDATEBOT_VERSION ${VERSION}
updatebot update
