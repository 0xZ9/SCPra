// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public rewardsToken;

    address public owner;

    // User address => staked amount
    mapping(address => uint) public balanceOf;
    // When did the user last claim their rewards
    mapping(address => uint) public lastClaim;
    // An array of all the rewards that were provided
    uint[] public globalRewards;
    // Total amount staked
    uint public totalStaked;
    // An array of total amount staked at reward distribution
    uint[] public historicalStaked;
    // The current reward distribution cycle
    uint public currentEpoch;

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    function stake(uint _amount) external {
        claimRewards();
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalStaked += _amount;
    }

    function withdraw(uint _amount) external {
        claimRewards();
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function distributeRewards (uint _amount) onlyOwner external {
        historicalStaked.push(totalStaked);
        rewardsToken.transferFrom(msg.sender, address(this), _amount);
        globalRewards.push(_amount);
        currentEpoch += 1;
    }

    function claimRewards () public {
        uint x = lastClaim[msg.sender];
        lastClaim[msg.sender] = currentEpoch;
        uint rewards;
        uint bal = balanceOf[msg.sender];
        for (x; x < currentEpoch; x++) 
        {
            uint y = globalRewards[x] * bal / historicalStaked[x];
            rewards += y;
        }
        rewardsToken.transfer(msg.sender, rewards);     
    }

    function updateRewardsToken(address _newToken) onlyOwner external {
        rewardsToken = IERC20(_newToken);
    }

    function changeOwner (address _newOwner) onlyOwner external {
        owner = _newOwner;
    }
}
