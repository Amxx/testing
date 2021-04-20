const { ethers, upgrades } = require('hardhat');

const argv = require('yargs/yargs')()
  .env('')
  .string('proxyAddress')
  .argv;

async function main() {
  const Impl2 = await ethers.getContractFactory('Impl2');
  const proxy = await upgrades.upgradeProxy(argv.proxyAddress, Impl2);

  console.log(`proxy updated: ${proxy.address}`);

  console.log('proxy.owner():', await proxy.owner())
  console.log('proxy.name():', await proxy.name())
  console.log('proxy.description():', await proxy.description())

  await (await proxy.setName('new name')).wait();
  await (await proxy.setDescription('new description')).wait();

  console.log('proxy.owner():', await proxy.owner())
  console.log('proxy.name():', await proxy.name())
  console.log('proxy.description():', await proxy.description())
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
