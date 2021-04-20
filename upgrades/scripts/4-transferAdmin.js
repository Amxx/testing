const { ethers, upgrades } = require('hardhat');

const argv = require('yargs/yargs')()
  .env('')
  .string('proxyAddress')
  .argv;

async function main() {
  const accounts = await ethers.getSigners();
  const instance = await upgrades.admin.getInstance();

  console.log(await instance.owner());
  await upgrades.admin.transferProxyAdminOwnership(accounts[1].address);
  console.log(await instance.owner());

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
