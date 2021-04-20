require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

const settings = {
  optimizer: {
    enabled: true,
    runs: 200,
  },
};

module.exports = {
  solidity: {
    compilers: [
      { version: '0.5.16', settings },
      { version: '0.6.12', settings },
      { version: '0.7.6',  settings },
      { version: '0.8.3',  settings },
    ],
  },
};
