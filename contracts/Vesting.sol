//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
    uint256 private cliff = 0 * 30 days;
    uint256 private duration = 0 * 30 days;
    uint256 public totalTokensLeftForVesting;

    IERC20 public token;

    enum Roles {
        Advisors,
        Partners,
        Mentors
    }

    Roles private role;

    struct Beneficiary {
        address beneficiary;
        Roles role;
        uint256 vestingStartTime;
        uint256 vestingcliffExpiryTime;
        uint256 vestingDurationExpiryTime;
        bool isVestingRevoked;
        uint256 fullyVestedAmount;
        uint256 currentVestedAmount;
        uint256 tokensReleasedTillNow;
        uint256 tokensWithdrawn;
    }

    mapping(uint256 => uint256) public totalTokensAvaliablePerRole;
    mapping(address => Beneficiary) public beneficiaries;
    mapping(address => uint256) public tokensWithdrawable;
    mapping(uint256 => uint256) private tgePercentage;

    event beneficiaryAdded(address _beneficiary, Roles _role);
    event tokensReleased(address _beneficiary, uint256 tokensWithdrawable);
    event tokensWithdrawn(address _beneficiary, uint256 _tokens);

    constructor(IERC20 _token) {
        token = _token;
        setTGEPercent();
    }

    modifier onlyBeneficiary(address _beneficiary) {
        require(beneficiaries[_beneficiary].beneficiary == _beneficiary,"Not a Valid Beneficiary");
        _;
    }

    modifier isRevoked(address _beneficiary) {
        require(
            !beneficiaries[_beneficiary].isVestingRevoked,
            "Can't proceed, beneficiary revoked."
        );
        _;
    }

    function setVestingAndTokenAllocationDetails(
        uint256 _cliffPeriodInDays,
        uint256 _vestingDurationInDays,
        uint256 _advisorPercent,
        uint256 _PartnerPercent,
        uint256 _mentorPercent
    ) public onlyOwner {
        cliff = _cliffPeriodInDays * 1 days;
        duration = _vestingDurationInDays * 1 days;
        tgePercentage[0] = _advisorPercent;
        tgePercentage[1] = _PartnerPercent;
        tgePercentage[2] = _mentorPercent;
    }

    function setTGEPercent() private onlyOwner {
        tgePercentage[0] = 5;
        tgePercentage[1] = 10;
        tgePercentage[2] = 7;
    }

    function allocateTokensForRoles() public onlyOwner {
        /// @dev Token balance of this contract

        uint256 totalTokenAllocatedForRoles;
        uint256 contractTokenBalance = IERC20(token).balanceOf(
            address(this)
        );
        require(
            contractTokenBalance > 0,
            "No tokens allocated to the contract"
        );
        
        totalTokensAvaliablePerRole[0] =
            (contractTokenBalance * tgePercentage[0]) /
            100;
        totalTokensAvaliablePerRole[1] =
            (contractTokenBalance * tgePercentage[1]) /
            100;
        totalTokensAvaliablePerRole[2] =
            (contractTokenBalance * tgePercentage[2]) /
            100;

        totalTokenAllocatedForRoles =
            totalTokensAvaliablePerRole[0] +
            totalTokensAvaliablePerRole[1] +
            totalTokensAvaliablePerRole[2];

        totalTokensLeftForVesting =
            contractTokenBalance -
            totalTokenAllocatedForRoles;
    }

    function addBeneficiary(
        address _beneficiary,
        Roles _role,
        uint256 _amount
    ) public onlyOwner {
        require(_beneficiary != owner(), "Owner cannot be a beneficiary");
        require(
            _beneficiary != address(0),
            "can't set null address as beneficiary"
        );
        require(_amount != 0, "amount should be greater than 0");

        // Check if beneficiary already present

        require(
            validateBeneficiary(_beneficiary),
            "beneficiary already present."
        );

        // check if tokens are avaliable for that specific role

        require(
            totalTokensAvaliablePerRole[uint256(_role)] >= _amount,
            "Tokens not allocated or tokens limit per role exhausted."
        );

        // adjust total value of tokens avaliable for role
        totalTokensAvaliablePerRole[uint256(_role)] -= _amount;

        // add a new beneficiary
        Beneficiary memory beneficiary = Beneficiary(
            _beneficiary,
            _role,
            block.timestamp,
            block.timestamp + cliff,
            block.timestamp + cliff + duration,
            false,
            _amount,
            _amount,
            0,
            0
        );

        beneficiaries[_beneficiary] = beneficiary;

        emit beneficiaryAdded(_beneficiary, _role);
    }

    function validateBeneficiary(address _beneficiary)
        private
        onlyOwner
        view
        returns (bool)
    {
        return beneficiaries[_beneficiary].beneficiary == address(0);
    }

    function revokeBeneficiary(address _beneficiary) public onlyOwner {
        require(
            !validateBeneficiary(_beneficiary),
            "Beneficiary does not exist."
        );
        require(
            !beneficiaries[_beneficiary].isVestingRevoked,
            "beneficiary already revoked."
        );
        beneficiaries[_beneficiary].isVestingRevoked = true;
    }

    function releaseTokens(address _beneficiary) public onlyOwner onlyBeneficiary(_beneficiary) {
        uint256 releasableTokens;
        uint256 tokensToBeReleased;
        require(
            !validateBeneficiary(_beneficiary),
            "Beneficiary does not exist."
        );
        require(
            !beneficiaries[_beneficiary].isVestingRevoked,
            "Can't proceed, beneficiary revoked."
        );
        // Get total tokens that can be released at a specific time.
        releasableTokens = getTokensToRelease(_beneficiary);
        // calculate tokens to release by substracting already received tokens.
        tokensToBeReleased =
            releasableTokens -
            beneficiaries[_beneficiary].tokensReleasedTillNow;
        // update released tokens for a beneficiary value
        beneficiaries[_beneficiary].tokensReleasedTillNow += tokensToBeReleased;

        //update the tokensWithdrawable value
        tokensWithdrawable[_beneficiary] += tokensToBeReleased;
        // update the currentVestedTokens value
        beneficiaries[_beneficiary].currentVestedAmount -= tokensToBeReleased;

        // emit the event
        emit tokensReleased(_beneficiary, tokensWithdrawable[_beneficiary]);
    }

    function withdrawTokens(address _beneficiary, uint256 _amount) public {
        releaseTokens(_beneficiary);
        require(_amount > 0, "Withdrawable amount should be greater than 0");
        require(
            tokensWithdrawable[_beneficiary] >= _amount,
            "Insufficient Funds, Please lower the amount to withdraw."
        );

        // update the withdraw tokens value
        tokensWithdrawable[_beneficiary] -= _amount;

        // update tokens received value
        beneficiaries[_beneficiary].tokensWithdrawn += _amount;

        //transfer the tokens to beneficiary

        IERC20(token).transfer(_beneficiary , _amount);

        //emit the event
        emit tokensWithdrawn(_beneficiary, _amount);
    }

    function getTokensToRelease(address _beneficiary)
        private
        view
        returns (uint256)
    {
        require(
            block.timestamp >=
                cliff + beneficiaries[_beneficiary].vestingStartTime,
            "Tokens not released yet."
        );

        // release total vested tokens if complete vesting duration is passed.
        if (
            block.timestamp >=
            beneficiaries[_beneficiary].vestingDurationExpiryTime
        ) {
            return beneficiaries[_beneficiary].fullyVestedAmount;
        } else {
            // release partial vested tokens based on vesting duration passed.
            return
                (beneficiaries[_beneficiary].fullyVestedAmount *
                    (block.timestamp -
                        beneficiaries[_beneficiary].vestingcliffExpiryTime)) /
                duration;
        }
    }

    function getTokensReleased(address _beneficiary)
        public
        isRevoked(_beneficiary)
        onlyOwner
        onlyBeneficiary(_beneficiary)
        view
        returns (uint256)
    {
        return tokensWithdrawable[_beneficiary];
    }

    function getTokensWithdrawn(address _beneficiary)
        public
        isRevoked(_beneficiary)
        onlyOwner
        onlyBeneficiary(_beneficiary)
        view
        returns (uint256)
    {
        return beneficiaries[_beneficiary].tokensWithdrawn;
    }
}
