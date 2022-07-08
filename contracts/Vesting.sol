//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
    uint256 private cliff;
    uint256 private duration;

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
        uint256 vestedAmount;
        uint256 tokensWithdrawn;
    }

    mapping(uint256 => uint256) public totalTokensAvaliablePerRole;
    mapping(address => Beneficiary) public beneficiaries;
    mapping(uint256 => uint256) private tgePercentage;

    event BeneficiaryAdded(address _beneficiary, Roles _role);
    event TokensReleased(address _beneficiary, uint256 tokensWithdrawable);
    event TokensWithdrawn(address _beneficiary, uint256 _tokens);

    constructor(IERC20 _token) {
        token = _token;
        setTGEPercent();
    }

    function setVestingAndTokenAllocationDetails(
        uint256 _cliffPeriodInDays,
        uint256 _vestingDurationInDays,
        uint256 _advisorPercent,
        uint256 _PartnerPercent,
        uint256 _mentorPercent
    ) external onlyOwner {
        cliff = _cliffPeriodInDays * 1 days;
        duration = _vestingDurationInDays * 1 days;
        tgePercentage[0] = _advisorPercent;
        tgePercentage[1] = _PartnerPercent;
        tgePercentage[2] = _mentorPercent;
    }

    function allocateTokensForRoles() external onlyOwner {
        
        // Token balance of this contract
        uint256 contractTokenBalance = IERC20(token).balanceOf(
            address(this)
        );
        require(
            contractTokenBalance > 0,
            "No tokens allocated to the contract"
        );
        //allocate tokens to specific roles
        totalTokensAvaliablePerRole[0] =
            (contractTokenBalance * tgePercentage[0]) /
            100;
        totalTokensAvaliablePerRole[1] =
            (contractTokenBalance * tgePercentage[1]) /
            100;
        totalTokensAvaliablePerRole[2] =
            (contractTokenBalance * tgePercentage[2]) /
            100;

    }

    function addBeneficiary(
        address _beneficiary,
        Roles _role,
        uint256 _amount
    ) external onlyOwner {
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
            0
        );

        beneficiaries[_beneficiary] = beneficiary;

        emit BeneficiaryAdded(_beneficiary, _role);
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

    function revokeBeneficiary(address _beneficiary) external onlyOwner {
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

    function releaseTokens(address _beneficiary) external onlyBeneficiary(_beneficiary) {
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
            beneficiaries[_beneficiary].tokensWithdrawn;
        // update released tokens for a beneficiary value
        beneficiaries[_beneficiary].tokensWithdrawn += tokensToBeReleased;

        // update tokens received value
        beneficiaries[_beneficiary].tokensWithdrawn += tokensToBeReleased;

        //transfer the tokens to beneficiary

        IERC20(token).transfer(_beneficiary , tokensToBeReleased);

        // emit the event
        emit TokensReleased(_beneficiary, tokensToBeReleased);
        emit TokensWithdrawn(_beneficiary,tokensToBeReleased);
    }

    function getTokensWithdrawn(address _beneficiary)
        external
        isRevoked(_beneficiary)
        onlyBeneficiary(_beneficiary)
        view
        returns (uint256)
    {
        return beneficiaries[_beneficiary].tokensWithdrawn;
    }

    function setTGEPercent() private onlyOwner {
        tgePercentage[0] = 5;
        tgePercentage[1] = 10;
        tgePercentage[2] = 7;
    }

    function validateBeneficiary(address _beneficiary)
        private
        onlyOwner
        view
        returns (bool)
    {
        return beneficiaries[_beneficiary].beneficiary == address(0);
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
            return beneficiaries[_beneficiary].vestedAmount;
        } else {
            // release partial vested tokens based on vesting duration passed.
            return
                (beneficiaries[_beneficiary].vestedAmount *
                    (block.timestamp -
                        beneficiaries[_beneficiary].vestingcliffExpiryTime)) /
                duration;
        }
    }


}
