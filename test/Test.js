const Token = artifacts.require("GATCoin");
var VestingContract = artifacts.require("./vestingnew.sol");

var chai = require("chai");

const BN = web3.utils.BN;
const chaiBN = require("chai-bn")(BN);
chai.use(chaiBN);

var chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);

const expect = chai.expect;

let instance;
let vestingInstance;
let totalSupply;

contract("all tests", async (accounts) => {
  describe("GATCoin Tests", async () => {
    const [initialHolder, beneficiaryOne, beneficiaryTwo, beneficiaryThree] =
      accounts;

    before(async () => {
      instance = await Token.deployed();
      vestingInstance = await VestingContract.deployed();
      totalSupply = await instance.totalSupply();
    });

    it("All tokens should be in my account", async () => {
      await expect(
        instance.balanceOf(initialHolder)
      ).to.eventually.be.a.bignumber.equal(new BN(totalSupply));
    });

    it("can transfer all tokens from owner account to vesting contract account", async () => {
      const sendTokens = await instance.balanceOf(initialHolder);
      await expect(
        instance.balanceOf(initialHolder)
      ).to.eventually.be.a.bignumber.equal(totalSupply);
      await expect(instance.transfer(VestingContract.address, sendTokens)).to
        .eventually.be.fulfilled;
      await expect(
        instance.balanceOf(initialHolder)
      ).to.eventually.be.a.bignumber.equal(new BN(0));
      await expect(
        instance.balanceOf(VestingContract.address)
      ).to.eventually.be.a.bignumber.equal(new BN(sendTokens));
    });

    describe("Vesting Tests", async () => {
      it("has enough funds to allocate token balance to specific Roles", async () => {
        let balance;
        balance = await instance.balanceOf(vestingInstance.address);
        expect(balance).to.be.a.bignumber.equal(totalSupply);
      });

      it("can allocate tokens to roles as per percentage", async () => {
        await vestingInstance.allocateTokensForRoles();
        expect(
          await vestingInstance.totalTokensAvaliablePerRole(0)
        ).to.be.a.bignumber.equal(new BN((5 / 100) * totalSupply));
        expect(
          await vestingInstance.totalTokensAvaliablePerRole(1)
        ).to.be.a.bignumber.equal(new BN((10 / 100) * totalSupply));
        expect(
          await vestingInstance.totalTokensAvaliablePerRole(2)
        ).to.be.a.bignumber.equal(new BN((7 / 100) * totalSupply));
      });

      it("can add a new beneficiary", async () => {
        await vestingInstance.addBeneficiary(beneficiaryOne, 0, 5000);
        await vestingInstance.addBeneficiary(beneficiaryTwo, 1, 10000);
        await vestingInstance.addBeneficiary(beneficiaryThree, 2, 7000);
        //checks if the beneficiary is already present
        await expect(vestingInstance.addBeneficiary(beneficiaryOne, 0, 5000)).to
          .be.rejected;

        //owner cant be a Beneficiary
        await expect(vestingInstance.addBeneficiary(initialHolder, 0, 5000)).to
          .be.rejected;

        //checks tokensPerRole Limit
        await expect(
          vestingInstance.addBeneficiary(initialHolder, 0, 50000000000)
        ).to.be.rejected;

        expect(
          await vestingInstance.beneficiaries(beneficiaryOne)
        ).to.be.not.equal(null);
        expect(
          await vestingInstance.beneficiaries(beneficiaryTwo)
        ).to.be.not.equal(null);
        expect(
          await vestingInstance.beneficiaries(beneficiaryThree)
        ).to.be.not.equal(null);

        //checks if total number of tokens avaliable per role value is adjusted
        expect(
          await vestingInstance.totalTokensAvaliablePerRole(0)
        ).to.be.a.bignumber.equal(new BN((5 / 100) * totalSupply - 5000));
        expect(
          await vestingInstance.totalTokensAvaliablePerRole(1)
        ).to.be.a.bignumber.equal(new BN((10 / 100) * totalSupply - 10000));
        expect(
          await vestingInstance.totalTokensAvaliablePerRole(2)
        ).to.be.a.bignumber.equal(new BN((7 / 100) * totalSupply - 7000));
      });

      it("can release tokens based on cliff and vesting duration", async () => {
        
        let beneficiary = await vestingInstance.beneficiaries(beneficiaryTwo);

        // check the vested amount and tokensWithdrawn value
        expect(beneficiary.vestedAmount).to.be.a.bignumber.equal(new BN(10000));
        expect(beneficiary.tokensWithdrawn).to.be.a.bignumber.equal(
          new BN(0)
        );

        //check for the initial token balance of benefeciary
        let balanceBefore = await instance.balanceOf(beneficiaryTwo);
        expect(balanceBefore).to.be.a.bignumber.equal(new BN(0));

        await expect(vestingInstance.releaseTokens(beneficiaryTwo)).to.be
          .fulfilled;
        

        //checks if VestedAmount is adjusted
        beneficiary = await vestingInstance.beneficiaries(beneficiaryTwo);
        expect(beneficiary.vestedAmount).to.be.a.bignumber.equal(new BN(0));

        //checks if tokensWithdrawn value is adjusted
        expect(beneficiary.tokensWithdrawn).to.be.a.bignumber.equal(
          new BN(10000)
        );

        //checks if tokens are transfered
        expect(
          await instance.balanceOf(beneficiaryTwo)
        ).to.be.a.bignumber.equal(new BN(10000));
      });

      it("can revoke a Benficiary", async () => {
        await vestingInstance.revokeBeneficiary(beneficiaryThree);
        const result = await vestingInstance.beneficiaries(beneficiaryThree);
        expect(result.isVestingRevoked).to.equal(true);
      });

      it("can check for total number of tokens withdrawn", async () => {
        let data = await vestingInstance.beneficiaries(beneficiaryTwo);
        expect(data.tokensWithdrawn).to.be.a.bignumber.equal(new BN(10000));
      });
    });
  });
});
