const { expect, assert  } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");

describe("Unspent Transaction Output contract", function() {

  let token;
  let accounts;
  let timstamp = Date.now();

  before(async () => {
    const contract = await ethers.getContractFactory("UTXOToken");
    token = await contract.deploy();
    accounts = await ethers.getSigners();
    await token.deployed();
  });

  it("Mint", async function() {
    // await time.increaseTo(timstamp);
    await token.mint(10000,[10000,accounts[0].address]);
    const totalSupply = await token.totalSupply();
    expect(await token.balanceOf(accounts[0].address)).to.equal(totalSupply.toNumber());
  });

  it("Retrieve UTXO data", async function() {
    const utxo  = await token.utxo(0);
    // const abiCoder = new ethers.utils.AbiCoder();
    // const data = abiCoder.decode(["uint256"],utxo.data)
    expect(utxo.amount.toNumber()).to.equal(10000);
    expect(utxo.owner).to.equal(accounts[0].address);
    // expect(data.toString()).to.equal(timstamp);
    expect(utxo.spent).to.equal(false);
  });

  it("Spent UTXO", async function(){
    const hashed = ethers.utils.solidityKeccak256(["uint256"],[0]);
    const sig = await accounts[0].signMessage(ethers.utils.arrayify(hashed));
    const address = ethers.utils.verifyMessage(ethers.utils.arrayify(hashed),sig);
    await token["transfer(address,uint256,(uint256,bytes))"](accounts[1].address, 10000, [0,sig]);
    expect(await token.balanceOf(address)).to.equal(0);
    expect(await token.balanceOf(accounts[1].address)).to.equal(10000);
  });

  it("Spend expire utxo", async function() {
    await token.mint(10000,[10000,accounts[0].address]);
    const utxo  = await token.utxo(1);
    const abiCoder = new ethers.utils.AbiCoder();
    const data = abiCoder.decode(["uint256"],utxo.data)
    await time.increaseTo(data);
    const hashed = ethers.utils.solidityKeccak256(["uint256"],[1]);
    const sig = await accounts[0].signMessage(ethers.utils.arrayify(hashed));
    await expect(
      token["transfer(address,uint256,(uint256,bytes))"]
      (accounts[1].address, 10000, [1,sig]))
      .to.be.revertedWith( "UTXO has been expired");
  });
  
  // @TODO
  it("approve", async function() {});

  // @TODO
  it("transferFrom", async function (){});

  // @TODO
  it("allowance", async function (){});
  
});