var GATCoin = artifacts.require("./GATCoin.sol");
var VestingContract = artifacts.require("./Vesting.sol");

module.exports = async function (deployer) {
    let deployedGATCoin;
    await deployer.deploy(GATCoin, 1);
    deployedGATCoin = await GATCoin.deployed();
    await deployer.deploy(VestingContract,deployedGATCoin.address);
};
