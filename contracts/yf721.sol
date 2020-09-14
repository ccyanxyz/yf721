pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./rnd.sol";
import "./IYF721Piece.sol";

contract YF721 is ERC721 {
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

	uint256 burnedCounter = 0;

	constructor(
		address _y,
		address _f,
		address _seven,
		address _two,
		address _one
	) ERC721("YF721", "YF721") public {
		_Y = IYF721Piece(_y); 
		_F = IYF721Piece(_f); 
		_7 = IYF721Piece(_seven); 
		_2 = IYF721Piece(_two); 
		_1 = IYF721Piece(_one); 
	}

	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
		uint256 rnd = UniformRandomNumber.uniform(seed, 10000);
		return rnd;
	}

	function mintYF721(uint256 id1, uint256 id2, uint256 id3, uint256 id4, uint256 id5) external {
		_Y.burn(id1); _F.burn(id2); _7.burn(id3); _2.burn(id4); _1.burn(id5);
		uint256 tokenId = _getNextTokenId();
		_mint(msg.sender, tokenId);
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
