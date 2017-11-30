#!/bin/bash
set -e

SSH_KEY=/app/deploy.key
# Deploy vars
DEPLOY_SRC=/app/docs/dist
DEPLOY_DEST=/tank/data/bitnami-ui
DEPLOY_USER=deploy
DEPLOY_URL=bitnami-ui-dev.nami

# This script will deploy the Bitnami UI project to bitnami-ui-dev.nami

## Configure ssh key for deployment
if  [ -f $SSH_KEY ]; then
  mkdir -p /root/.ssh
  cp $SSH_KEY /root/.ssh/id_rsa
  chown root:root /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa
fi

if [ ! -z ${DEPLOY_TAG+x} ]; then
  echo "Switching to $DEPLOY_TAG"
  git checkout $DEPLOY_TAG
fi

# Compile the project. Now, we are deploying to staging server, so
# we compile the documentation with the distributed CSS files
npm run dist

# Copy the generated output to the server
if [ $? -eq 0 ]; then
  if [ -z ${DEPLOY_TAG+x} ]; then
    echo "Deploying current version"
    scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $DEPLOY_SRC/* $DEPLOY_USER@$DEPLOY_URL:$DEPLOY_DEST
  fi
  # Publish the version in a specific folder too

  if git describe --exact-match >&/dev/null; then
    echo "Deploying $TAG tag"
    TAG=$(git describe --exact-match)
    ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$DEPLOY_URL "mkdir -p $DEPLOY_DEST/$TAG"
    scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $DEPLOY_SRC/* $DEPLOY_USER@$DEPLOY_URL:$DEPLOY_DEST/$TAG
  fi
fi
