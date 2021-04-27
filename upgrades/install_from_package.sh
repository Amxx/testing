#!/bin/bash

rm -rf node_modules/@openzeppelin/upgrades-core
rm -rf node_modules/@openzeppelin/hardhat-upgrades
npm i ../../openzeppelin-upgrades/packages/core/openzeppelin-upgrades-core-v1.6.0.tgz
npm i ../../openzeppelin-upgrades/packages/plugin-hardhat/openzeppelin-hardhat-upgrades-v1.6.0.tgz
