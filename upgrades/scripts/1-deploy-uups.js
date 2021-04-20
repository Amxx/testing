const { ethers, upgrades } = require('hardhat');

async function main() {
  const Impl1 = await ethers.getContractFactory('Impl1UUPS');
  const proxy = await upgrades.deployProxy(Impl1, ['some name', 'some description'], { kind: 'uups' });

  console.log(`proxy deployed: ${proxy.address}`);

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
