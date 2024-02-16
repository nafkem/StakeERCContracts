// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract Stake {
    
    bool internal locked;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 internal MAX_INT = 2**256 - 1;

    // Contract owner
    address public owner;

    // Timestamp related variables
    mapping(address => uint256) initialStakingTimestamp;
    bool public timePeriodSet;
    uint256 public timePeriod;

    // Yield related variables
    bool public percentageSet;
    uint256 public percentageBasisPoints;
    mapping(address => uint256) expectedInterest;
    uint256 public totalExpectedInterest;


    // Token amount variables
    mapping(address => uint256) balances;
    uint256 public totalStateStaked;

    // ERC20 contract address
    IERC20 public erc20Contract;

    // Events
    event TokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);
    event InterestEarned(address to, uint256 amount);
    event InterestWithdrawn(address to, uint256 amount);

    //  _erc20_contract_address.
    constructor(IERC20 _erc20_address) {
        owner = msg.sender;
        timePeriodSet = false;
        percentageSet = false;
        // Set the erc20 contract address which this timelock is deliberately paired to
        require(address(_erc20_contract_address) != address(0), "_erc20_contract_address address can not be zero");
        require(address(msg.sender) != address(), "owner address can not be 0xC2C...F7221");
        erc20Contract = _erc20_address;
        locked = false;
        // Initialize the total amount of STATE staked
        totalStateStaked = 0;
        // Initialize the time period
        timePeriod = 0;
        // Initialize the base points (bps)
        percentageBasisPoints = 0;
        // Initialize total expectedinterest
        totalExpectedInterest = 0;
    }

    // Modifier
    
    modifier () {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Message sender must be the contract's owner.");
        _;
    }
    modifier timePeriodNotSet() {
        require(timePeriodSet == false, "The time stamp has already been set.");
        _;
    }
    modifier timePeriodIsSet() {
        require(timePeriodSet == true, "Please set the time stamp first, then try again.");
        _;
    }
    modifier percentageNotSet() {
        require(percentageSet == false, "The percentageBasisPoints has already been set.");
        _;
    }
    modifier percentageIsSet() {
        require(percentageSet == true, "Please set the percentageBasisPoints variable first, then try again.");
        _;
    }
    
    /// @dev Sets the staking period for this specific contract instance (in seconds) i.e. 3600 = 1 hour
    function setTimePeriod(uint256 _timePeriodInSeconds) public onlyOwner timePeriodNotSet  {
        timePeriodSet = true;
        timePeriod = _timePeriodInSeconds;
    }
    /// 1 wei is equivalent to 0.01%
    function setPercentage(uint256 _percentageBasisPoints) public onlyOwner percentageNotSet  {
        require(_percentageBasisPoints >= 1 && _percentageBasisPoints <= 10000, "Percentage must be a value >=1 and <= 10000");
        percentageSet = true;
        percentageBasisPoints = _percentageBasisPoints;
    }
    // @return amount of tokens currently staked
    function getTotalStakedStake() public view returns (uint256) {
        return totalStateStaked;
        }

    // @return amount of tokens currently owned to users
    function getTotalExpectedInterest() public view returns (uint256) {
        return totalExpectedInterest;
        }

    // return amount of tokens
    function getReservePoolAmount(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
        }
    // amount to allocate to recipient.
    function stakeTokens(IERC20 token, uint256 amount) public timePeriodIsSet percentageIsSet noReentrant{
        require(token == erc20Contract, "You are only allowed to stake the official erc20 token address");
        require(amount <= token.balanceOf(msg.sender), "Not enough ERC20 tokens in your wallet");
        // Ensure minimum "amount" requirements
        require(amount > 315360000000, "Amount to stake must be greater than 0.00000031536 ETH");
        require(amount < MAX_INT.div(10000) , "Maximum amount must be smaller, please try again");
        // If this is the first time an external account address is staking, then we need to set the initial staking timestamp to the currently block's timestamp
        if (initialStakingTimestamp[msg.sender] == 0){
            initialStakingTimestamp[msg.sender] = block.timestamp;
        }
        uint256 interestEarnedPerAnnum_pre = amount.mul(percentageBasisPoints);
        uint256 interestEarnedPerAnnum_post = interestEarnedPerAnnum_pre.div(10000);
        // Let's calculate how many wei are earned per second
        uint256 weiPerSecond = interestEarnedPerAnnum_post.div(31536000);
        require(weiPerSecond > 0, "Interest on this amount is too low to calculate, please try a greater amount");
        // Let's calculate the release date
        uint256 releaseEpoch = initialStakingTimestamp[msg.sender].add(timePeriod);
        // Test to see if the term has already ended
        require(block.timestamp < releaseEpoch, "Term has already ended");
        
        require(secondsRemaining > 0, "There is not enough time left");
        // There are 31536000 seconds per annum
        uint256 interestEarnedForThisStake = weiPerSecond.mul(secondsRemaining);
        require(token.balanceOf(address(this)) >= totalStateStaked.add(totalExpectedInterest).add
        (interestEarnedForThisStake), "Not enough STATE tokens in the reserve pool");

        // Adding this user's new expected interest
        totalExpectedInterest = totalExpectedInterest.add(interestEarnedForThisStake);
        // Increment (up from being reset to zero)
        expectedInterest[msg.sender] = expectedInterest[msg.sender].add(interestEarnedForThisStake);
        emit TokensStaked(msg.sender, newAmountToInvest);
        emit InterestEarned(msg.sender, interestEarnedForThisStake);
    }

    //Transfer tokens (back to owner)
    function transferTokensOutOfReservePool(IERC20 token, uint256 amount) external onlyOwner {
        require(address(token) != address(0), "Token address can not be zero");
        require(token == erc20Contract, "Token address must be ERC20 address which was passed into the constructor");
        require(amount <= token.balanceOf(address(this)).sub((totalExpectedInterest.add(totalStateStaked))), "Can only remove tokens which are spare i.e. not put aside for end user pay out");
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        token.safeTransfer(owner, amount);
    }
}