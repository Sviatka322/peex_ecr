#!/bin/bash

SWAP_LATEST=$1
VERSION=$(cat VERSION)
ECR_URI=857848095906.dkr.ecr.us-east-1.amazonaws.com/test_app
ECR_NAME=test_app

# Checking if the current version image exists in the ECR repo
aws --profile ecr_peex ecr describe-images --repository-name "$ECR_NAME" --image-ids imageTag="$VERSION" --region us-east-1 > /dev/null 2>&1
if [ $? -eq 0 ]; then 
    printf "image with version: $VERSION already exists in repo\n"
    exit 1
fi

# Getting ECR credentials for Docker
printf "Logininig to repo"
aws --profile ecr_peex ecr get-login-password --region us-east-1 | docker login -u AWS --password-stdin "$ECR_URI" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    printf "Logged in successfully\n"
else
    printf "Logininig failed\n"
    exit 1
fi

# Building image
docker build -t django-web-app .

# Checking if an image with the 'latest' tag exists
aws --profile ecr_peex ecr describe-images --repository-name "$ECR_NAME" --image-ids imageTag=latest --region us-east-1 > /dev/null 2>&1
if [ $? -ne 0 ]; then   
    printf "Image with 'latest' tag not found in $ECR_URI ecr repo!\n"
    printf "Creating Image with 'latest' tag"

    # Setting SWAP_LATEST variable to 'None' to avoid single image retaging.
    if [ "$SWAP_LATEST" == "--latest" ]; then
        SWAP_LATEST="None"
    fi

    # Tagging image
    docker tag django-web-app "$ECR_URI":latest
    docker tag django-web-app "$ECR_URI":"$VERSION"
else
    printf "Creating image version: $VERSION\n"

    # Tagging image
    docker tag django-web-app "$ECR_URI":"$VERSION"
fi

# Pushing image in ECR
docker push "$ECR_URI" --all-tags

# Demonstrate swaping latest tag
# Checking if SWAP_LATEST is None (for user inform)
if [ "$SWAP_LATEST" == "None" ]; then
    printf "Cannot swap latest tag. Latest tag has been created here.\n"
fi

# Moving the 'latest' tag to new image.
if [ "$SWAP_LATEST" == "--latest" ]; then
    printf "Moving 'latest' tag to image version: $VERSION\n"
    aws --profile ecr_peex ecr batch-delete-image --repository-name "$ECR_NAME" --image-ids imageTag=latest --region us-east-1 > /dev/null 2>&1
    NEW_LATEST_MANIFEST=$(aws ecr batch-get-image --repository-name "$ECR_NAME" --image-ids imageTag="$VERSION" --output json --region us-east-1 | jq --raw-output --join-output '.images[0].imageManifest')
    aws ecr put-image --repository-name "$ECR_NAME" --image-tag latest --image-manifest "$NEW_LATEST_MANIFEST" --region us-east-1 > /dev/null 2>&1
fi

# Removing local images
printf "Removing local images\n"
docker rmi -f $(docker images -aq) > /dev/null 2>&1
