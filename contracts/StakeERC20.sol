// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Staking {

    address stoken;
    uint256 public rewardRate;
    address owner;

    struct StakerData {
        uint256 totalStaked;
        uint256 lastStakedTimestamp;
        uint256 reward;
    }

    mapping(address => StakerData) stakers;
    
    constructor(address _stoken) {
        stoken = _stoken;
        owner = msg.sender;
    }
    function calculateReward(address _user) external view returns (uint256) {
        StakerData storage staker = stakers[_user];
        uint256 stakingDuration = block.timestamp.sub(staker.lastStakedTimestamp);
        return staker.totalStaked.mul(rewardRate).mul(stakingDuration).div(100);
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        stoken.transferFrom(msg.sender, address(this), amount);
        StakerData storage staker = stakers[msg.sender];
        staker.reward = staker.reward.add(calculateReward(msg.sender));
        staker.totalStaked = staker.totalStaked.add(amount);
        staker.lastStakedTimestamp = block.timestamp;
    }

    function unstake(uint256 amount) public {
        StakerData storage staker = stakers[msg.sender];
        require(staker.totalStaked >= amount, "Not enough staked tokens");
        staker.reward = staker.reward.add(calculateReward(msg.sender));
        staker.totalStaked = staker.totalStaked.sub(amount);
        staker.lastStakedTimestamp = block.timestamp;

        stoken.transfer(msg.sender, amount);
    }

    function claimReward() external {
        staker.lastStakedTimestamp = block.timestamp;
        StakerData storage staker = stakers[msg.sender];
        uint256 reward = staker.reward.add(calculateReward(msg.sender));
        require(reward > 0, "No reward to claim");
        stoken.transfer(msg.sender, reward);
        staker.reward = 0;
       

    }

}