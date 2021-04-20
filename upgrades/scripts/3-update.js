const { ethers, upgrades } = require('hardhat');

const argv = require('yargs/yargs')()
  .env('')
  .string('proxyAddress')
  .argv;

async function main() {
  const Impl3 = await ethers.getContractFactory('Impl3');
  const proxy = await upgrades.upgradeProxy(argv.proxyAddress, Impl3);

  console.log(`proxy updated: ${proxy.address}`);

  console.log('proxy.owner():', await proxy.owner())
  console.log('proxy.name():', await proxy.name())
  console.log('proxy.description():', await proxy.description())
  console.log('proxy.uri():', await proxy.uri())

  await (await proxy.setURI('some uri')).wait();

  console.log('proxy.owner():', await proxy.owner())
  console.log('proxy.name():', await proxy.name())
  console.log('proxy.description():', await proxy.description())
  console.log('proxy.uri():', await proxy.uri())
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
