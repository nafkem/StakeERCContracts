// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

    function calculateReward(address _user) public view returns (uint256) {
        StakerData memory staker = stakers[_user];
        uint256 stakingDuration = block.timestamp - staker.lastStakedTimestamp;
        return staker.totalStaked * rewardRate * stakingDuration / 100;
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(stoken).transferFrom(msg.sender, address(this), _amount);
        StakerData memory staker = stakers[msg.sender];
        staker.reward += (calculateReward(msg.sender));
        staker.totalStaked += _amount;
        staker.lastStakedTimestamp = block.timestamp;
    }

    function unstake(uint256 _amount) public {
        StakerData memory staker = stakers[msg.sender];
        require(staker.totalStaked >= _amount, "Not enough staked tokens");
        staker.reward += calculateReward(msg.sender);
        staker.totalStaked += _amount;
        staker.lastStakedTimestamp = block.timestamp;

        IERC20(stoken).transfer(msg.sender, _amount);
    }
    function claimReward() external {
        StakerData memory staker = stakers[msg.sender];
        staker.lastStakedTimestamp = block.timestamp;        
        staker.reward += calculateReward(msg.sender);
        require(staker.reward > 0, "No reward to claim");
        IERC20(stoken).transfer(msg.sender, staker.reward);
        staker.reward = 0;
    }


}