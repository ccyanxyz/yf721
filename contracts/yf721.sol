pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./rnd.sol";

contract YF721 is ERC721 {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
	uint256 constant public mintPieceFee = 100 * 1e18;
	IERC20 public YF20;
	address public prizePool;
	address constant public burnAddress = 0x00000000000000000000000000000000DeaDBeef;
	
	uint256 public yf721Count;
	uint256 public yf721PieceCount;
	uint256 public burnRatio = 500; // 50%

	uint256 public countdown = 1 hours;
	uint256 public lastMintTime;
	address public lastMinter;

	bytes32 public _Y; 
	bytes32 public _F;
	bytes32 public _7;
	bytes32 public _2;
	bytes32 public _1;
    
    struct YF721Token {
        uint256 id;
		string char; // YF721
    }
	mapping(uint256 => YF721Token) tokens;
    uint256 burnedCounter = 0;

	struct Winner {
		uint256 timestamp;
		uint256 tokenId;
		address owner;
	}
	Winner[] public winners;

	address owner;
    constructor(
		address _yf20
	) ERC721("YF721", "YF721") public {
		owner = msg.sender;
		yf721Count = 0;
		yf721PieceCount = 0;
		YF20 = IERC20(_yf20);
		prizePool = burnAddress;

		_Y = keccak256(bytes("Y")); 
		_F = keccak256(bytes("F")); 
		_7 = keccak256(bytes("7")); 
		_2 = keccak256(bytes("2")); 
		_1 = keccak256(bytes("1")); 
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

	function getWinnersLength() external view returns (uint256) {
		return winners.length;
	}

	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
		uint256 rnd = UniformRandomNumber.uniform(seed, 10000);
		return rnd;
	}

	function getYF721Count() external view returns (uint256) {
		return yf721Count;
	}

	function getYF721PieceCount() external view returns (uint256) {
		return yf721PieceCount;
	}

	function getYF721Info(uint256 idx) external view returns (string memory) {
		return tokens[idx].char;
	}

	function mintYF721Piece() external {
		require(msg.sender == tx.origin);
		YF20.safeTransferFrom(msg.sender, address(this), mintPieceFee);
		YF20.safeTransferFrom(address(this), burnAddress, mintPieceFee.mul(burnRatio).div(1000));
		YF20.safeTransferFrom(address(this), prizePool, YF20.balanceOf(address(this)));
		uint256 rnd = getRandom();
		string memory char;
		if (rnd >= 9980) {
			// 0.002
			char = "1";
		} else if (rnd >= 9960) {
			// 0.004
			char = "2";
		} else if (rnd >= 9860) {
			// 0.014
			char = "7";
		} else if (rnd >= 7000) {
			// 0.3
			char = "F";
		} else if (rnd >= 5000) {
			// 0.5
			char = "Y";
		} else {
			char = "Don't give up, bro!";
		}
		uint256 tokenId = _getNextTokenId();
		tokens[tokenId] = YF721Token(tokenId, char);
		yf721PieceCount += 1;
		_mint(msg.sender, tokenId);

		if(lastMintTime == 0) {
			lastMintTime = block.timestamp;
			lastMinter = msg.sender;
		} else {
			if(lastMintTime.add(countdown) < block.timestamp) {
				tokenId = _getNextTokenId();
				tokens[tokenId] = YF721Token(tokenId, "YF721");
				_mint(lastMinter, tokenId);
				winners.push(Winner(block.timestamp, tokenId, lastMinter));

				lastMinter = msg.sender;
				lastMintTime = block.timestamp;
			}
		}
	}

	function check(uint256 id, bytes32 v) internal view returns (bool) {
		YF721Token memory token = tokens[id];
		return ownerOf(id) == msg.sender && keccak256(bytes(token.char)) == v;
	}

	function burnIt(uint256 id) external {
		require(ownerOf(id) == msg.sender);
		_burn(id);
	}

	function mintFomo721(uint256 id1, uint256 id2, uint256 id3, uint256 id4, uint256 id5) external {
		require(check(id1, _Y) && check(id2, _F) && check(id3, _7) && check(id4, _2) && check(id5, _1), "check failed");
		_burn(id1); _burn(id2); _burn(id3); _burn(id4); _burn(id5);
		yf721PieceCount = yf721PieceCount.sub(5);
		uint256 tokenId = _getNextTokenId();
		tokens[tokenId] = YF721Token(tokenId, "YF721");
		_mint(msg.sender, tokenId);
		yf721Count = yf721Count.add(1);
	}

    function _getNextTokenId() private view returns (uint256) {
        return totalSupply().add(1).add(burnedCounter);
    }

    function _burn(uint256 _tokenId) override internal {
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
