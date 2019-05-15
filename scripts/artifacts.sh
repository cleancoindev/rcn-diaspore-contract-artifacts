#!/usr/bin/env bash

# to run: sh artifacts.sh master v1.0.9-beta "Auto release 1.0.9"

# define absolute path to rcn-diaspore-core and rcn-diaspore-contract-artifacts projects
PATH_CORE="/Users/jpgonzalezra/Documents/Code/ripio/rcn-network"
PATH_CONTRACT_ARTIFACTS="/Users/jpgonzalezra/Documents/Code/rcn-diaspore-contract-artifacts"

# define absolute path to rcn-diaspore-abi-wrappers if you want automate the json to ts transformation
PATH_ABI_WRAPPERS="/Users/jpgonzalezra/Documents/Code/rcn-diaspore-abi-wrappers"
# define absolute path to rcn-diaspore-contract-wrappers if you want update rcn packages
PATH_CONTRACT_WRAPPERS="/Users/jpgonzalezra/Documents/Code/rcn-diaspore-contract-wrapper"

# params validation
if [[ -z "$1" ]]; then
  echo "Branch is empty"
  exit 1
fi
if [[ -z "$2" ]]; then
  echo "Tag is empty"
  exit 1
fi
if [[ -z "$3" ]]; then
  echo "Comment commit is empty"
  exit 1
fi

# pull the last commit from rcn-network and compile .sol files into .json abi files
cd $PATH_CORE
git checkout $1 && git pull
rm -rf build/contracts
truffle compile

# clear artifacts folder from rcn-diaspore-contract-artifacts and copy the new ones from rcn-network
rm -rf $PATH_CONTRACT_ARTIFACTS/artifacts/*
for file in $(<"$PATH_CONTRACT_ARTIFACTS/scripts/contracts.txt");
do cp "build/contracts/$file" "$PATH_CONTRACT_ARTIFACTS/artifacts";
done

# build the new json abi files, push it and tag it to a new version
cd $PATH_CONTRACT_ARTIFACTS
yarn clean && yarn build
git add --all && git commit -m "$3" && git push origin master && git tag -a $2 -m "$3" && git push origin $2

echo "\nArtifacts successfully updated..."

# start subsequent process if user want it
if [[ -n "$4" ]]; then
  echo "\nStarting rcn-diaspore-abi-wrappers process..."
  cd $PATH_ABI_WRAPPERS
  sh scripts/generator.sh $2
  cd $PATH_CONTRACT_WRAPPERS
  sh scripts/updater.sh $2
fi