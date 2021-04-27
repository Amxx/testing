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

const OPERATION =[
  'mint',
  'transfer',
  'empty',
];
const STATE = [
  'clean',
  'dirty',
]
const COLUMNS = [].concat(...STATE.map(a => OPERATION.map(b => [].concat(a, b)))).map(([state, operation]) => `${operation} (${state})`);

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
      this.report.push({ name, values: this.results });
    });
  });
}


describe('GasUsage', async function() {
  before(function() {
    this.report = [];
  });
  describe('without delegate', async function () {
    for (const flavor of ['ERC20Mock', 'ERC20SnapshotEveryBlockMock', 'ERC20VotesMock', 'ERC20VotesLightMock']) {
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
      'ERC20VotesLightMock-delegated',
      (admin) => deploy('ERC20VotesLightMock', 'name', 'symbol'),
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
    console.log(`| Description | ${COLUMNS.filter((_, i) => i % 3 != 0).join(' | ')} |`);
    console.log('|-|-:|-:|-:|-:|-:|-:|');
    this.report.forEach(({ name, values }) =>
      console.log(`| ${name.padEnd(30)} | ${values.filter((_, i) => i % 3 != 0).map(value => value.padStart(6)).join(' | ')} |`)
    );
  });
});

/**
 ******************************************************************************
 * RESULTS
 ******************************************************************************

 */
