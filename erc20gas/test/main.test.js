const { ethers } = require('hardhat');
const { expect } = require('chai');

async function deploy(name, ...params) {
  const Contract = await ethers.getContractFactory(name);
  return await Contract.deploy(...params).then(f => f.deployed());
}

async function getGasUsage(tx) {
  return (await (await tx).wait()).gasUsed.toString();
}

async function _measure(token, accounts, opts = {}) {
  if (opts.before) {
    for (const account of accounts) { await opts.before(token, account); }
  }
  const mint     = await getGasUsage(opts.mint(token, accounts[0].address, 100));
  const transfer = await getGasUsage(token.connect(accounts[0]).transfer(accounts[1].address, 10));
  const empty    = await getGasUsage(token.connect(accounts[0]).transfer(accounts[2].address, await token.balanceOf(accounts[0].address)));
  return [mint,transfer, empty];
}

async function measure(name, deploy, opts = {}) {
  describe(name, function () {
    before(function () {
      this.results = [];
    });

    it(`with clean accounts`, async function () {
      const accounts = await ethers.getSigners();
      const token    = await deploy(accounts[0]);
      this.results.push(...await _measure(token, accounts.slice(1), {
        ...opts,
        prefix: `${name}|clean`,
      }));
    });
    it(`with dirty accounts`, async function () {
      const accounts = await ethers.getSigners();
      const token    = await deploy(accounts[0]);
      this.results.push(...await _measure(token, accounts.slice(1), {
        ...opts,
        prefix: `${name}|dirty`,
        before: async (token, account) => {
          opts.before && await opts.before(token, account);
          await opts.mint(token, account.address, 1);
        }
      }));
    });
    after(function () {
      this.report.push(`| ${name.padEnd(30)} | ${this.results.map(value => value.padStart(6)).join(' | ')} |`);
    });
  });
}


describe('GasUsage', async function() {
  before(function() {
    this.report = [];
  });
  describe('without delegate', async function () {
    for (const flavor of ['ERC20Mock', 'ERC20SnapshotEveryBlockMock', 'ERC20VotesMock']) {
      measure(
        flavor,
        (admin) => deploy(flavor, 'name', 'symbol'),
        {
          mint: (token, to, value) => token.mint(to, value),
        },
      );
    }
    measure(
      'Comp',
      (admin) => deploy('Comp', admin.address),
      { mint: (token, to, value) => token.transfer(to, value) },
    );
  });

  describe('with delegate', async function () {
    measure(
      'ERC20VotesMock-delegated',
      (admin) => deploy('ERC20VotesMock', 'name', 'symbol'),
      {
        mint: (token, to, value) => token.mint(to, value),
        before: (token, account) => token.connect(account).delegate(account.address),
      },
    );
    measure(
      'Comp-delegated',
      (admin) => deploy('Comp', admin.address),
      {
        mint: (token, to, value) => token.transfer(to, value),
        before: (token, account) => token.connect(account).delegate(account.address),
      },
    );
  });
  after(function () {
    console.log('| Description | mint (clean) | transfer (clean) | empty (clean) | mint (dirty) | transfer (dirty) | empty (dirty) |');
    console.log('|-|-:|-:|-:|-:|-:|-:|');
    this.report.forEach(line => console.log(line));
  });
});

/**
 ******************************************************************************
 * RESULTS
 ******************************************************************************

 */
