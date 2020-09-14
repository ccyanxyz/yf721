pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LPTokenWrapper {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public LPT;
	constructor(address _lpt) public {
		LPT = IERC20(_lpt);
	}

	uint256 public _totalSupply;
	mapping(address => uint256) public _balances;

	uint256 public _profitPerShare; // x 1e18, monotonically increasing.
	mapping(address => uint256) public _unrealized; // x 1e18
	mapping(address => uint256) public _realized; // last paid _profitPerShare
	event LPTPaid(address indexed user, uint256 profit);

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function unrealizedProfit(address account) public view returns (uint256) {
		return _unrealized[account].add(_balances[account].mul(_profitPerShare.sub(_realized[account])).div(1e18));
	}    

	modifier update(address account) {
		// Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
		// really i know you think you do but you don't
		// https://etherscan.io/address/0xb3775fb83f7d12a36e0475abdd1fca35c091efbe#code
		if (account != address(0)) {
			_unrealized[account] = unrealizedProfit(account);
			_realized[account] = _profitPerShare;
		}
		_;
	}    

	function stake(uint256 amount) update(msg.sender) public virtual {
		_totalSupply = _totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		LPT.safeTransferFrom(msg.sender, address(this), amount);
	}

	function withdraw(uint256 amount) update(msg.sender) public virtual {
		_totalSupply = _totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		LPT.safeTransfer(msg.sender, amount);
	}

	function claim() update(msg.sender) public {
		uint256 profit = _unrealized[msg.sender];
		if (profit != 0) {
			_unrealized[msg.sender] = 0;
			LPT.safeTransfer(msg.sender, profit);
			emit LPTPaid(msg.sender, profit);
		}
	}
}

contract YF721Pool is LPTokenWrapper {
	uint256 public DURATION = 7 days;
	uint256 public initReward = 10000 * 1e18;
	uint256 public startTime;
	uint256 public periodFinish;
	uint256 public rewardRate;
	uint256 public lastUpdateTime;
	uint256 public rewardPerTokenStored;
	uint256 public devFee = 30; // 30 / 1000 = 3%
	uint256 public poolShare = 100; // 100 / 1000 = 10%
	address public devAddress;
	address public prizePool;

	mapping(address => uint256) public userRewardPerTokenPaid;
	mapping(address => uint256) public rewards;

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);

	IERC20 public YF20;

	constructor(
		address _lpt,
		address _yf20,
		address _devaddr,
		address _prizepool
	) LPTokenWrapper(_lpt) public {
		_balances[msg.sender] = 1; // avoid divided by 0
		_totalSupply = 1;
		prizePool = _prizepool;
		devAddress = _devaddr;
		YF20 = IERC20(_yf20);
	}

	modifier updateReward(address account) {
		rewardPerTokenStored = rewardPerToken();
		lastUpdateTime = lastTimeRewardApplicable();
		if (account != address(0)) {
			rewards[account] = earned(account);
			userRewardPerTokenPaid[account] = rewardPerTokenStored;
		}
		_;
	}

	function lastTimeRewardApplicable() public view returns (uint256) {
		return Math.min(block.timestamp, periodFinish);
	}

	function rewardPerToken() public view returns (uint256) {
		return
		rewardPerTokenStored.add(
			lastTimeRewardApplicable()
			.sub(lastUpdateTime)
			.mul(rewardRate)
			.mul(1e18)
			.div(totalSupply())
		);
	}

	function earned(address account) public view returns (uint256) {
		return
		balanceOf(account)
		.mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
		.div(1e18)
		.add(rewards[account]);
	}

	// stake visibility is public as overriding LPTokenWrapper's stake() function
	function stake(uint256 amount) public override updateReward(msg.sender) checkHalve checkStart {
		require(amount != 0, "Cannot stake 0");
		super.stake(amount);
		emit Staked(msg.sender, amount);
	}

	function withdraw(uint256 amount) public override updateReward(msg.sender) checkStart {
		require(amount != 0, "Cannot withdraw 0");
		super.withdraw(amount);
		emit Withdrawn(msg.sender, amount);
	}

	function exit() external {
		withdraw(balanceOf(msg.sender));
		getReward();
		claim();
	}

	function getReward() public updateReward(msg.sender) checkHalve checkStart {
		uint256 reward = earned(msg.sender);
		uint256 devReward = reward.mul(devFee).div(1000);
		uint256 poolReward = reward.mul(poolShare).div(1000);
		reward = reward.sub(devReward).sub(poolReward);
		if (reward != 0) {
			rewards[msg.sender] = 0;
			YF20.safeTransfer(devAddress, devReward);
			YF20.safeTransfer(prizePool, poolReward);
			YF20.safeTransfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}

	modifier checkStart() {
		require(block.timestamp > startTime, "not yet");
		_;
	}

	modifier checkHalve() {
		if (block.timestamp >= periodFinish) {
			initReward = initReward.mul(50).div(100);
			rewardRate = initReward.div(DURATION);
			periodFinish = block.timestamp.add(DURATION);
		}
		_;
	}

	/**
	* @dev This function must be triggered by the contribution token approve-and-call fallback.
	*      It will update reward rate and time.
		* @param _amount Amount of reward tokens added to the pool
	*/
	function receiveApproval(uint256 _amount) external updateReward(address(0)) {
		require(_amount != 0, "Cannot approve 0");

		if (block.timestamp >= periodFinish) {
			rewardRate = _amount.div(DURATION);
		} else {
			uint256 remaining = periodFinish.sub(block.timestamp);
			uint256 leftover = remaining.mul(rewardRate);
			rewardRate = _amount.add(leftover).div(DURATION);
		}
		lastUpdateTime = block.timestamp;
		periodFinish = block.timestamp.add(DURATION);

		YF20.safeTransferFrom(msg.sender, address(this), _amount);
		emit RewardAdded(_amount);
	}
}
