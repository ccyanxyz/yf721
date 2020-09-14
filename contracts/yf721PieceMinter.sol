pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./rnd.sol";
import "./IYF721Piece.sol";


contract YF721PieceMinter {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 constant public mintPieceFee = 1 * 1e18;
	IERC20 public YF20;
	address public prizePool;
	address constant public burnAddress = 0x00000000000000000000000000000000DeaDBeef;

	uint256 public burnRatio = 500; // 50%

	IYF721Piece public _Y;
	IYF721Piece public _F;
	IYF721Piece public _7;
	IYF721Piece public _2;
	IYF721Piece public _1;

	uint256 public _ychance = 5000;
	uint256 public _fchance = 7000;
	uint256 public _7chance = 9860;
	uint256 public _2chance = 9960;
	uint256 public _1chance = 9980;

	uint256 burnedCounter = 0;

	address owner;
	constructor(
		address _yf20,
		address _y,
		address _f,
		address _seven,
		address _two,
		address _one
	) public {
		owner = msg.sender;
		YF20 = IERC20(_yf20);
		prizePool = burnAddress;

		_Y = IYF721Piece(_y);
		_F = IYF721Piece(_f);
		_7 = IYF721Piece(_seven);
		_2 = IYF721Piece(_two);
		_1 = IYF721Piece(_one);
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyOnce() {
		require(prizePool == burnAddress);
		_;
	}

	function setPrizePool(address _prizepool) external onlyOwner onlyOnce {
		prizePool = _prizepool;
	}

	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
		uint256 rnd = UniformRandomNumber.uniform(seed, 10000);
		return rnd;
	}

	function mintPiece() external {
		require(msg.sender == tx.origin);
		YF20.safeTransferFrom(msg.sender, address(this), mintPieceFee);
		YF20.safeTransferFrom(address(this), burnAddress, mintPieceFee.mul(burnRatio).div(1000));
		YF20.safeTransferFrom(address(this), prizePool, YF20.balanceOf(address(this)));
		uint256 rnd = getRandom();
		if(rnd >= _1chance) {
			_1.mint(msg.sender);
		} else if(rnd >= _2chance) {
			_2.mint(msg.sender);
		} else if(rnd >= _7chance) {
			_7.mint(msg.sender);
		} else if(rnd >= _fchance) {
			_F.mint(msg.sender);
		} else if(rnd >= _ychance) {
			_Y.mint(msg.sender);
		}/* else {
		// Don't give up, bro!
	}*/
}
}
