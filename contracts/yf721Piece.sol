pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./rnd.sol";

contract YF721Piece is ERC721 {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 burnedCounter = 0;

	address owner;
	constructor(
		string memory _char
	) ERC721(_char, "YF721 Piece") public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function setMinter(address _minter) external onlyOwner {
		owner = _minter;
	}

	function mint(address _to) onlyOwner external {
		_mint(_to, _getNextTokenId());
	}

	function _getNextTokenId() private view returns (uint256) {
		return totalSupply().add(1).add(burnedCounter);
	}

	function burn(uint256 _tokenId) external {
		require(msg.sender == ownerOf(_tokenId));
		super._burn(_tokenId);
		burnedCounter++;
	}

	function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
		uint256 tokenCount = balanceOf(_owner);

		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 resultIndex = 0;
			uint256 _tokenIdx;
			for (_tokenIdx = 0; _tokenIdx < tokenCount; _tokenIdx++) {
				result[resultIndex] = tokenOfOwnerByIndex(_owner, _tokenIdx);
				resultIndex++;
			}
			return result;
		}
	}
}
