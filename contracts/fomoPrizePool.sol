pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./rnd.sol";

interface IFOMO721 is IERC721 {
	function getFomo721Info(uint256 index) external view returns (string memory);
}

contract FomoPrizePool {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
	IERC20 public FomoToken;
	IFOMO721 public Fomo721;
	uint256 public minFomo = 10 * 1e18;
	address constant public burnAddress = 0x00000000000000000000000000000000DeaDBeef;

	constructor(
		address _fomotoken,
		address _fomo721
	) public {
		FomoToken = IERC20(_fomotoken);
		Fomo721 = IFOMO721(_fomo721);
	}

	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
        uint256 rnd = UniformRandomNumber.uniform(seed, 700);
		return rnd;
	}

	modifier onlyFomoHolder() {
		require(FomoToken.balanceOf(msg.sender) >= minFomo);
		_;
	}

	function isFomo721(uint256 id) internal view returns (bool) {
		string memory char = Fomo721.getFomo721Info(id);
		return keccak256(bytes(char)) == keccak256(bytes("Fomo721"));
	}

	function draw(uint256 tokenId) external onlyFomoHolder {
		require(Fomo721.ownerOf(tokenId) == msg.sender);
		require(isFomo721(tokenId));
		Fomo721.safeTransferFrom(msg.sender, burnAddress, tokenId);
		uint256 rnd = getRandom();
		uint256 reward = FomoToken.balanceOf(address(this)).mul(rnd.add(700).div(10000));
		FomoToken.safeTransferFrom(address(this), msg.sender, reward);
	}
}
