// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "./Mole.sol";

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Copied and modified from sushiswap code:
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol

interface IMigrator {
    function replaceMigrate(IBEP20 lpToken) external returns (IBEP20, uint);

    function migrate(IBEP20 lpToken) external returns (IBEP20, uint);
}

// MoleThrower is the master of Mole.
contract MoleThrower is Ownable {

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 pendingReward;
        bool unStakeBeforeEnableClaim;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Moles to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Moles distribution occurs.
        uint256 accMolePerShare; // Accumulated Moles per share, times 1e12. See below.
        uint256 totalDeposit;       // Accumulated deposit tokens.
        IMigrator migrator;
    }

    // The Mole !
    Mole public mole;

    // Dev address.
    address public devAddr;

    // Percentage of developers mining
    uint256 public devMiningRate;

    // PIGGY tokens created per block.
    uint256 public molePerBlock;

    // The block number when WPC mining starts.
    uint256 public startBlock;

    // The block number when WPC claim starts.
    uint256 public enableClaimBlock;

    // Interval blocks to reduce mining volume.
    uint256 public reduceIntervalBlock;

    // reduce rate
    uint256 public reduceRate;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => address[]) public userAddresses;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid);
    event UnStake(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ReplaceMigrate(address indexed user, uint256 pid, uint256 amount);
    event Migrate(address indexed user, uint256 pid, uint256 targetPid, uint256 amount);

    constructor (
        Mole _mole,
        address _devAddr,
        uint256 _molePerBlock,
        uint256 _startBlock,
        uint256 _enableClaimBlock,
        uint256 _reduceIntervalBlock,
        uint256 _reduceRate,
        uint256 _devMiningRate
    ) public {
        mole = _mole;
        devAddr = _devAddr;
        molePerBlock = _molePerBlock;
        startBlock = _startBlock;
        reduceIntervalBlock = _reduceIntervalBlock;
        reduceRate = _reduceRate;
        devMiningRate = _devMiningRate;
        enableClaimBlock = _enableClaimBlock;

        totalAllocPoint = 0;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function usersLength(uint256 _pid) external view returns (uint256) {
        return userAddresses[_pid].length;
    }

    // Update dev address by the previous dev.
    function setDevAddr(address _devAddr) public onlyOwner {
        devAddr = _devAddr;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(uint256 _pid, IMigrator _migrator) public onlyOwner {
        poolInfo[_pid].migrator = _migrator;
    }

    // set the enable claim block
    function setEnableClaimBlock(uint256 _enableClaimBlock) public onlyOwner {
        enableClaimBlock = _enableClaimBlock;
    }

    // set molePerBlock
    function setMolePerBlock(uint256 _molePerBlock) public onlyOwner {
        molePerBlock = _molePerBlock;
    }

    // update reduceIntervalBlock
    function setReduceIntervalBlock(uint256 _reduceIntervalBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        reduceIntervalBlock = _reduceIntervalBlock;
    }

    // Update the given pool's PIGGY allocation point. Can only be called by the owner.
    function setAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        //update totalAllocPoint
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);

        //update poolInfo
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // update reduce rate
    function setReduceRate(uint256 _reduceRate, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        reduceRate = _reduceRate;
    }

    // update dev mining rate
    function setDevMiningRate(uint256 _devMiningRate) public onlyOwner {
        devMiningRate = _devMiningRate;
    }

    // Migrate lp token to another lp contract.
    function replaceMigrate(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        IMigrator migrator = pool.migrator;
        require(address(migrator) != address(0), "migrate: no migrator");

        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        (IBEP20 newLpToken, uint mintBal) = migrator.replaceMigrate(lpToken);

        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;

        emit ReplaceMigrate(address(migrator), _pid, bal);
    }

    // Move lp token data to another lp contract.
    function migrate(uint256 _pid, uint256 _targetPid, uint256 begin) public onlyOwner {

        require(begin < userAddresses[_pid].length, "migrate: begin error");

        PoolInfo storage pool = poolInfo[_pid];
        IMigrator migrator = pool.migrator;
        require(address(migrator) != address(0), "migrate: no migrator");

        IBEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        (IBEP20 newLpToken, uint mintBal) = migrator.migrate(lpToken);

        PoolInfo storage targetPool = poolInfo[_targetPid];
        require(address(targetPool.lpToken) == address(newLpToken), "migrate: bad");

        uint rate = mintBal.mul(1e12).div(bal);
        for (uint i = begin; i < begin.add(20); i++) {

            if (i < userAddresses[_pid].length) {
                updatePool(_targetPid);

                address addr = userAddresses[_pid][i];
                UserInfo storage user = userInfo[_pid][addr];
                UserInfo storage tUser = userInfo[_targetPid][addr];

                if (user.amount <= 0) {
                    continue;
                }

                uint tmp = user.amount.mul(rate).div(1e12);

                tUser.amount = tUser.amount.add(tmp);
                tUser.rewardDebt = tUser.rewardDebt.add(user.rewardDebt.mul(rate).div(1e12));
                targetPool.totalDeposit = targetPool.totalDeposit.add(tmp);
                pool.totalDeposit = pool.totalDeposit.sub(user.amount);
                user.rewardDebt = 0;
                user.amount = 0;
            } else {
                break;
            }

        }

        emit Migrate(address(migrator), _pid, _targetPid, bal);

    }

    // Safe mole transfer function, just in case if rounding error causes pool to not have enough Mole.
    function safeMoleTransfer(address _to, uint256 _amount) internal {
        uint256 moleBal = mole.balanceOf(address(this));
        if (_amount > moleBal) {
            mole.transfer(_to, moleBal);
        } else {
            mole.transfer(_to, _amount);
        }
    }

    // Return molePerBlock, baseOn power  --> molePerBlock * (reduceRate/100)^power
    function getMolePerBlock(uint256 _power) public view returns (uint256){
        if (_power == 0) {
            return molePerBlock;
        } else {
            uint256 z = molePerBlock;
            for (uint256 i = 0; i < _power; i++) {
                z = z.mul(reduceRate).div(1000);
            }
            return z;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see all pending Mole on frontend.
    function allPendingMole(address _user) external view returns (uint256){
        uint sum = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            sum = sum.add(_pending(i, _user));
        }
        return sum;
    }

    // View function to see pending Mole on frontend.
    function pendingMole(uint256 _pid, address _user) external view returns (uint256) {
        return _pending(_pid, _user);
    }

    //internal function
    function _pending(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accMolePerShare = pool.accMolePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // pending mole reward
            uint256 moleReward = 0;
            uint256 lastRewardBlockPower = pool.lastRewardBlock.sub(startBlock).div(reduceIntervalBlock);
            uint256 blockNumberPower = block.number.sub(startBlock).div(reduceIntervalBlock);

            // get moleReward from pool.lastRewardBlock to block.number.
            // different interval different multiplier and molePerBlock, sum moleReward
            if (lastRewardBlockPower == blockNumberPower) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                moleReward = moleReward.add(multiplier.mul(getMolePerBlock(blockNumberPower)).mul(pool.allocPoint).div(totalAllocPoint));
            } else {
                for (uint256 i = lastRewardBlockPower; i <= blockNumberPower; i++) {
                    uint256 multiplier = 0;
                    if (i == lastRewardBlockPower) {
                        multiplier = getMultiplier(pool.lastRewardBlock, startBlock.add(lastRewardBlockPower.add(1).mul(reduceIntervalBlock)).sub(1));
                    } else if (i == blockNumberPower) {
                        multiplier = getMultiplier(startBlock.add(blockNumberPower.mul(reduceIntervalBlock)), block.number);
                    } else {
                        multiplier = reduceIntervalBlock;
                    }
                    moleReward = moleReward.add(multiplier.mul(getMolePerBlock(i)).mul(pool.allocPoint).div(totalAllocPoint));
                }
            }

            accMolePerShare = accMolePerShare.add(moleReward.mul(1e12).div(lpSupply));
        }

        // get pending value
        uint256 pendingValue = user.amount.mul(accMolePerShare).div(1e12).sub(user.rewardDebt);

        // if enableClaimBlock after block.number, return pendingValue + user.pendingReward.
        // else return pendingValue.
        if (enableClaimBlock > block.number) {
            return pendingValue.add(user.pendingReward);
        } else if (user.pendingReward > 0 && user.unStakeBeforeEnableClaim) {
            return pendingValue.add(user.pendingReward);
        }
        return pendingValue;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // get moleReward. moleReward base on current MolePerBlock.
        uint256 power = block.number.sub(startBlock).div(reduceIntervalBlock);
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 moleReward = multiplier.mul(getMolePerBlock(power)).mul(pool.allocPoint).div(totalAllocPoint);

        // mint
        mole.mint(devAddr, moleReward.mul(devMiningRate).div(100));
        mole.mint(address(this), moleReward);

        //update pool
        pool.accMolePerShare = pool.accMolePerShare.add(moleReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;

    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, IMigrator _migrator, bool _withUpdate) public onlyOwner {

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

        //update totalAllocPoint
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        // add poolInfo
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accMolePerShare : 0,
        totalDeposit : 0,
        migrator : _migrator
        }));
    }

    // Stake LP tokens to MoleThrower for WPC allocation.
    function stake(uint256 _pid, uint256 _amount) public nonReentrant {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //update poolInfo by pid
        updatePool(_pid);

        // if user's amount bigger than zero, transfer Mole to user.
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMolePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                // if enableClaimBlock after block.number, save the pending to user.pendingReward.
                if (enableClaimBlock <= block.number) {
                    safeMoleTransfer(msg.sender, pending);

                    // transfer user.pendingReward if user.pendingReward > 0, and update user.pendingReward to 0
                    if (user.pendingReward > 0) {
                        safeMoleTransfer(msg.sender, user.pendingReward);
                        user.pendingReward = 0;
                    }
                } else {
                    user.pendingReward = user.pendingReward.add(pending);
                }
            }
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalDeposit = pool.totalDeposit.add(_amount);
            userAddresses[_pid].push(msg.sender);
        }

        user.rewardDebt = user.amount.mul(pool.accMolePerShare).div(1e12);

        emit Stake(msg.sender, _pid, _amount);

    }

    // UnStake LP tokens from MoleThrower.
    function unStake(uint256 _pid, uint256 _amount) public nonReentrant {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "unStake: not good");

        //update poolInfo by pid
        updatePool(_pid);

        //transfer Mole to user.
        uint256 pending = user.amount.mul(pool.accMolePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            // if enableClaimBlock after block.number, save the pending to user.pendingReward.
            if (enableClaimBlock <= block.number) {
                safeMoleTransfer(msg.sender, pending);

                // transfer user.pendingReward if user.pendingReward > 0, and update user.pendingReward to 0
                if (user.pendingReward > 0) {
                    safeMoleTransfer(msg.sender, user.pendingReward);
                    user.pendingReward = 0;
                }
            } else {
                user.pendingReward = user.pendingReward.add(pending);
                user.unStakeBeforeEnableClaim = true;
            }
        }

        if (_amount > 0) {
            // transfer LP tokens to user
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            // update user info
            user.amount = user.amount.sub(_amount);
            pool.totalDeposit = pool.totalDeposit.sub(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accMolePerShare).div(1e12);

        emit UnStake(msg.sender, _pid, _amount);
    }

    // claim MOLE
    function claim(uint256 _pid) public nonReentrant {

        require(enableClaimBlock <= block.number, "too early to claim");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //update poolInfo by pid
        updatePool(_pid);

        // if user's amount bigger than zero, transfer Mole to user.
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMolePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeMoleTransfer(msg.sender, pending);
            }
        }

        // transfer user.pendingReward if user.pendingReward > 0, and update user.pendingReward to 0
        if (user.pendingReward > 0) {
            safeMoleTransfer(msg.sender, user.pendingReward);
            user.pendingReward = 0;
        }

        // update user info
        user.rewardDebt = user.amount.mul(pool.accMolePerShare).div(1e12);

        emit Claim(msg.sender, _pid);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;

        pool.totalDeposit = pool.totalDeposit.sub(user.amount);
        // update user info
        user.amount = 0;
        user.rewardDebt = 0;

        // transfer LP tokens to user
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    //For voting
    function getBalance(uint256 _pid, address _user) public view returns (uint) {
        if (_pid + 1 > poolInfo.length) {
            return 0;
        }
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

}
