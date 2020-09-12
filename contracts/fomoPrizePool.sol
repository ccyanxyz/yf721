pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UniformRand/min-bound");
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

contract FomoPrizePool {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
	IERC20 constant public FomoToken = IERC20(0x00000000000000000000000000000000DeaDBeef);
	IERC721 constant public Fomo721 = IERC721(0x00000000000000000000000000000000DeaDBeef);
	address constant public burnAddress = 0x00000000000000000000000000000000DeaDBeef;
	uint256 constant public minFomo = 10 * 1e18;

	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
        uint256 rnd = UniformRandomNumber.uniform(seed, 700);
		return rnd;
	}

	modifier onlyFomoHolder() {
		require(FomoToken.balanceOf(msg.sender) >= minFomo);
		_;
	}

	function draw(uint256 tokenId) external onlyFomoHolder {
		require(Fomo721.ownerOf(tokenId) == msg.sender);
		Fomo721.safeTransferFrom(msg.sender, burnAddress, tokenId);
		uint256 rnd = getRandom();
		uint256 reward = FomoToken.balanceOf(address(this)).mul(rnd.add(700).div(10000));
		FomoToken.safeTransferFrom(address(this), msg.sender, reward);
	}
}
