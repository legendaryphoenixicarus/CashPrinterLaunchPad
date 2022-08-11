// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CashPrinterStaking is Ownable {
    string public name = "CashPrinter: Staking";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 pending;
        uint256 claimed;
        uint256 beginTime;
        uint256 endTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakeToken;
        uint256 totalTokenStaked;
        uint256 apr;
        uint256 totalTokenClaimed;
    }

    // Info of each pool.
    PoolInfo[] private poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() {}

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        IERC20 _stakeToken,
        uint256 _apr
    ) public onlyOwner {
        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                totalTokenStaked: 0,
                totalTokenClaimed: 0,
                apr: _apr
            })
        );
    }

    function setPool(
        uint256 _pid,
        IERC20 _stakeToken,
        uint256 _apr
    ) public onlyOwner {
        poolInfo[_pid].apr = _apr;
        poolInfo[_pid].stakeToken = _stakeToken;
    }

    function getTotalTokenStaked(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalTokenStaked;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (_amount > 0) {
            pool.stakeToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.beginTime = block.timestamp;
        if (_pid == 0) {
            user.endTime = block.timestamp + 7 days;
        } else if (_pid == 1) {
            user.endTime = block.timestamp + 14 days;
        } else if (_pid == 2) {
            user.endTime = block.timestamp + 30 days;
        } else if (_pid == 3) {
            user.endTime = block.timestamp + 60 days;
        } else if (_pid == 4) {
            user.endTime = block.timestamp + 90 days;
        } else if (_pid == 5) {
            user.endTime = block.timestamp + 180 days;
        }
        pool.totalTokenStaked = pool.totalTokenStaked.add(_amount);
        user.pending = user.amount.mul(pool.apr).div(365);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: bad request");
        require(user.endTime <= block.timestamp, "withdraw: need expired time");

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalTokenStaked = pool.totalTokenStaked.sub(_amount);
            uint256 reward = _amount.mul(pool.apr).div(365);
            user.pending = user.pending.sub(reward);

            pool.stakeToken.safeTransfer(address(msg.sender), _amount);

            if (user.endTime <= block.timestamp) {
                uint256 claimAmount = _amount.mul(pool.apr).div(365);
                user.claimed = user.claimed.add(claimAmount);
                user.pending = user.pending.sub(claimAmount);
                pool.totalTokenClaimed.add(claimAmount);
                pool.stakeToken.safeTransfer(address(msg.sender), claimAmount);
            }
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function getPoolInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            poolInfo[_pid].apr,
            poolInfo[_pid].totalTokenStaked,
            poolInfo[_pid].totalTokenClaimed
        );
    }
}
