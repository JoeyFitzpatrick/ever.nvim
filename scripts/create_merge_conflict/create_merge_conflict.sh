#!/bin/bash

# Initialize a git repository
rm -rf git-merge-test
mkdir git-merge-test
cd git-merge-test
git init

# Create a file and add content
echo "Initial content" > file.txt
git add file.txt
git commit -m "Initial commit"

# Create and switch to branch 'branch1'
git checkout -b branch1
echo "Content for branch1" > file.txt
git add file.txt
git commit -m "Commit on branch1"

# Switch back to the main branch
git checkout main

# Create and switch to branch 'branch2'
git checkout -b branch2
echo "Content for branch2" > file.txt
git add file.txt
git commit -m "Commit on branch2"

# Switch back to the main branch
git checkout main

# Attempt to merge branch1 - this should succeed
git merge branch1

# Attempt to merge branch2 - this will cause a conflict
git merge branch2
