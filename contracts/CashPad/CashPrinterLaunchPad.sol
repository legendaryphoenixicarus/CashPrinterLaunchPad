pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CashPrinterStaking.sol";

contract CashPad is Ownable, ReentrancyGuard {
    string public name = "CashPrinter: LaunchPad";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 CashPrinter;
    CashPrinterStaking cashPrinterStaking;

    address payable private ReceiveToken;

    struct IDOPool {
        uint256 id;
        uint256 begin;
        uint256 end;
        uint256 poolType; //1:public, 2:private
        address IDOToken;
        uint256 maxPurchaseTier1;
        uint256 maxPurchaseTier2; //==public tier
        uint256 maxPurchaseTier3;
        uint256 totalCap;
        uint256 minimumTokenSoldout;
        uint256 totalToken; //total sale token for this pool
        uint256 ratePerETH;
        bool isActived;
        uint256 lockDuration; //lock after purchase
        uint256 totalSold; //total number of token sold
    }

    struct User {
        uint256 id;
        address userAddress;
        bool isWhitelist;
        uint256 totalTokenPurchase;
        uint256 totalETHPurchase;
        uint256 purchaseTime;
        bool isActived;
        bool isClaimed;
    }

    mapping(uint256 => mapping(address => User)) public whitelist; //poolid - listuser

    IDOPool[] pools;

    constructor(
        address payable receiveTokenAdd,
        IERC20 cashPrinter,
        CashPrinterStaking _cashPrinterStaking
    ) public {
        ReceiveToken = receiveTokenAdd;
        CashPrinter = cashPrinter;
        cashPrinterStaking = _cashPrinterStaking;
    }

    function addWhitelist(address user, uint256 pid) public onlyOwner {
        whitelist[pid][user].id = pid;
        whitelist[pid][user].userAddress = user;
        whitelist[pid][user].isWhitelist = true;

        whitelist[pid][user].isActived = true;
    }

    function addMulWhitelist(address[] memory user, uint256 pid)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < user.length; i++) {
            whitelist[pid][user[i]].id = pid;
            whitelist[pid][user[i]].userAddress = user[i];
            whitelist[pid][user[i]].isWhitelist = true;

            whitelist[pid][user[i]].isActived = true;
        }
    }

    function updateWhitelist(
        address user,
        uint256 pid,
        bool isWhitelist,
        bool isActived
    ) public onlyOwner {
        whitelist[pid][user].isWhitelist = isWhitelist;
        whitelist[pid][user].isActived = isActived;
    }

    function IsWhitelist(address user, uint256 pid) public view returns (bool) {
        uint256 poolIndex = pid.sub(1);
        if (pools[poolIndex].poolType == 1) //public
        {
            return (whitelist[pid][user].isWhitelist &&
                whitelist[pid][user].isActived);
        } else if (pools[poolIndex].poolType == 2) //private
        {
            (
                uint256 amount,
                uint256 pending,
                uint256 claimed,
                uint256 beginTime,
                uint256 endTime
            ) = getUserStakingData(user, 0);
            return (amount >= 500 * 1e18);
        } else if (pools[poolIndex].poolType == 3) {
            //community round

            return true;
        } else {
            return false;
        }
    }

    function getUserStakingData(address user, uint256 poolId)
        public
        view
        returns (
            uint256 amount,
            uint256 pendingReward,
            uint256 rewardClaimed,
            uint256 beginTime,
            uint256 endTime
        )
    {
        return (cashPrinterStaking.userInfo(poolId, user));
    }

    function addPool(
        IDOPool memory _poolData
    ) public onlyOwner {
        uint256 id = pools.length.add(1);
        pools.push(
            IDOPool({
                id: id,
                begin: _poolData.begin,
                end: _poolData.end,
                poolType: _poolData.poolType,
                IDOToken: _poolData.IDOToken,
                maxPurchaseTier1: _poolData.maxPurchaseTier1,
                maxPurchaseTier2: _poolData.maxPurchaseTier2,
                maxPurchaseTier3: _poolData.maxPurchaseTier3,
                totalCap: _poolData.totalCap,
                totalToken: _poolData.totalToken,
                ratePerETH: _poolData.ratePerETH,
                isActived: true,
                lockDuration: _poolData.lockDuration,
                totalSold: 0,
                minimumTokenSoldout: _poolData.minimumTokenSoldout
            })
        );
    }

    function updatePool(
        uint256 pid,
        IDOPool memory _poolData
    ) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        if (_poolData.begin > 0) {
            pools[poolIndex].begin = _poolData.begin;
        }
        if (_poolData.end > 0) {
            pools[poolIndex].end = _poolData.end;
        }

        if (_poolData.maxPurchaseTier1 > 0) {
            pools[poolIndex].maxPurchaseTier1 = _poolData.maxPurchaseTier1;
        }
        if (_poolData.maxPurchaseTier2 > 0) {
            pools[poolIndex].maxPurchaseTier2 = _poolData.maxPurchaseTier2;
        }
        if (_poolData.maxPurchaseTier3 > 0) {
            pools[poolIndex].maxPurchaseTier3 = _poolData.maxPurchaseTier3;
        }
        if (_poolData.totalCap > 0) {
            pools[poolIndex].totalCap = _poolData.totalCap;
        }
        if (_poolData.totalToken > 0) {
            pools[poolIndex].totalToken = _poolData.totalToken;
        }
        if (_poolData.ratePerETH > 0) {
            pools[poolIndex].ratePerETH = _poolData.ratePerETH;
        }
        if (_poolData.lockDuration > 0) {
            pools[poolIndex].lockDuration = _poolData.lockDuration;
        }
        if (_poolData.minimumTokenSoldout > 0) {
            pools[poolIndex].minimumTokenSoldout = _poolData.minimumTokenSoldout;
        }
        if (_poolData.poolType > 0) {
            pools[poolIndex].poolType = _poolData.poolType;
        }
        pools[poolIndex].IDOToken = _poolData.IDOToken;
    }

    function stopPool(uint256 pid) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        pools[poolIndex].isActived = false;
    }

    function activePool(uint256 pid) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        pools[poolIndex].isActived = true;
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawErc20(IERC20 token) public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    //withdraw ETH after IDO
    function withdrawPoolFund() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        ReceiveToken.transfer(balance);
    }

    function purchaseIDO(uint256 pid) public payable nonReentrant {
        uint256 poolIndex = pid.sub(1);

        require(pools[poolIndex].isActived, "invalid pool");
        require(
            block.timestamp >= pools[poolIndex].begin &&
                block.timestamp <= pools[poolIndex].end,
            "invalid time"
        );
        //check user
        require(IsWhitelist(msg.sender, pid), "invalid user");

        //check amount
        uint256 ethAmount = msg.value;
        whitelist[pid][msg.sender].totalETHPurchase = whitelist[pid][msg.sender]
            .totalETHPurchase
            .add(ethAmount);

        if (pools[poolIndex].poolType == 2) {
            (
                uint256 stakeAmount,
                uint256 rewardPending,
                uint256 rewardClaimed,
                uint256 beginTime,
                uint256 endTime
            ) = getUserStakingData(msg.sender, 0);
            if (stakeAmount < 1500 * 1e18) {
                require(
                    whitelist[pid][msg.sender].totalETHPurchase <=
                        pools[poolIndex].maxPurchaseTier1,
                    "invalid maximum purchase for tier1"
                );
            } else if (
                stakeAmount >= 1500 * 1e18 && stakeAmount < 3000 * 1e18
            ) {
                require(
                    whitelist[pid][msg.sender].totalETHPurchase <=
                        pools[poolIndex].maxPurchaseTier2,
                    "invalid maximum purchase for tier2"
                );
            } else {
                require(
                    whitelist[pid][msg.sender].totalETHPurchase <=
                        pools[poolIndex].maxPurchaseTier3,
                    "invalid maximum purchase for tier3"
                );
            }
        } else if (pools[poolIndex].poolType == 1) {
            //public pool

            require(
                whitelist[pid][msg.sender].totalETHPurchase <=
                    pools[poolIndex].maxPurchaseTier2,
                "invalid maximum contribute"
            );
        } else {
            //community round
            require(
                whitelist[pid][msg.sender].totalETHPurchase <=
                    pools[poolIndex].maxPurchaseTier3 * 2,
                "invalid maximum contribute"
            );
        }

        uint256 tokenAmount = ethAmount.mul(pools[poolIndex].ratePerETH).div(
            1e18
        );

        uint256 remainToken = getRemainIDOToken(pid);
        require(
            remainToken > pools[poolIndex].minimumTokenSoldout,
            "IDO sold out"
        );
        require(remainToken >= tokenAmount, "IDO sold out");

        whitelist[pid][msg.sender].totalTokenPurchase = whitelist[pid][
            msg.sender
        ].totalTokenPurchase.add(tokenAmount);

        pools[poolIndex].totalSold = pools[poolIndex].totalSold.add(
            tokenAmount
        );
    }

    function claimToken(uint256 pid) public nonReentrant {
        require(!whitelist[pid][msg.sender].isClaimed, "user already claimed");
        uint256 poolIndex = pid.sub(1);

        require(
            block.timestamp >=
                pools[poolIndex].end.add(pools[poolIndex].lockDuration),
            "not on time for claiming token"
        );

        uint256 userBalance = getUserTotalPurchase(pid);

        require(userBalance > 0, "invalid claim");

        IERC20(pools[poolIndex].IDOToken).transfer(msg.sender, userBalance);
        whitelist[pid][msg.sender].isClaimed = true;
    }

    function getUserTotalPurchase(uint256 pid) public view returns (uint256) {
        return whitelist[pid][msg.sender].totalTokenPurchase;
    }

    function getRemainIDOToken(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        uint256 tokenBalance = getBalanceTokenByPoolId(pid);
        if (pools[poolIndex].totalSold > tokenBalance) {
            return 0;
        }

        return tokenBalance.sub(pools[poolIndex].totalSold);
    }

    function getBalanceTokenByPoolId(uint256 pid)
        public
        view
        returns (uint256)
    {
        uint256 poolIndex = pid.sub(1);
        //return pools[poolIndex].IDOToken.balanceOf(address(this));
        return pools[poolIndex].totalToken;
    }

    function getPoolInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            // uint256,
            // uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            address
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            pools[poolIndex].begin,
            pools[poolIndex].end,
            pools[poolIndex].poolType,
            //pools[poolIndex].AmountPBRRequire,
            //pools[poolIndex].MaxPurchase,
            pools[poolIndex].ratePerETH,
            pools[poolIndex].lockDuration,
            pools[poolIndex].totalSold,
            pools[poolIndex].isActived,
            pools[poolIndex].IDOToken
        );
    }

    function getPoolSoldInfo(uint256 pid)
        public
        view
        returns (uint256, uint256)
    {
        uint256 poolIndex = pid.sub(1);
        return (pools[poolIndex].lockDuration, pools[poolIndex].totalSold);
    }

    function getWhitelistfo(uint256 pid)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256,
            bool
        )
    {
        return (
            whitelist[pid][msg.sender].userAddress,
            whitelist[pid][msg.sender].isWhitelist,
            whitelist[pid][msg.sender].totalTokenPurchase,
            whitelist[pid][msg.sender].totalETHPurchase,
            whitelist[pid][msg.sender].isClaimed
        );
    }

    function getUserInfo(uint256 pid, address user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            bool
        )
    {
        return (
            whitelist[pid][user].isWhitelist,
            whitelist[pid][user].totalTokenPurchase,
            whitelist[pid][user].totalETHPurchase,
            whitelist[pid][user].isClaimed
        );
    }
}
