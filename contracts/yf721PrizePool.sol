pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./rnd.sol";

contract YF721PrizePool {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public YF20;
	IERC721 public YF721;
	uint256 public minYF20 = 10 * 1e18;
	address constant public burnAddress = 0x00000000000000000000000000000000DeaDBeef;

	constructor(
		address _yf20,
		address _yf721
	) public {
		YF20 = IERC20(_yf20);
		YF721 = IERC721(_yf721);
	}

	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
		uint256 rnd = UniformRandomNumber.uniform(seed, 700);
		return rnd;
	}

	modifier onlyYF20Holder() {
		require(YF20.balanceOf(msg.sender) >= minYF20);
		_;
	}

	function draw(uint256 tokenId) external onlyYF20Holder {
		require(YF721.ownerOf(tokenId) == msg.sender);
		YF721.safeTransferFrom(msg.sender, burnAddress, tokenId);
		uint256 rnd = getRandom();
		uint256 reward = YF20.balanceOf(address(this)).mul(rnd.add(700).div(10000));
		YF20.safeTransferFrom(address(this), msg.sender, reward);
	}
}
