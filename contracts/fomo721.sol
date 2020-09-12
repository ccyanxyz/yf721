pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./rnd.sol";

contract Fomo721 is ERC721 {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
	uint256 constant public mintPieceFee = 100 * 1e18;
	IERC20 public FomoToken;
	address public prizePool;
	address constant public burnAddress = 0x00000000000000000000000000000000DeaDBeef;
	
	uint256 public fomo721Count;
	uint256 public fomo721PieceCount;
	uint256 public burnRatio = 500; // 50%

	bytes32 public _F; 
	bytes32 public _o;
	bytes32 public _m;
	bytes32 public _7;
	bytes32 public _2;
	bytes32 public _1;
    
    struct Fomo721Token {
        uint256 id;
		string char; // Fomo721
    }
	mapping(uint256 => Fomo721Token) tokens;
    uint256 burnedCounter = 0;

	address owner;
    constructor(
		string memory _name,
		string memory _symbol,
		address _fomotoken
	) ERC721(_name, _symbol) public {
		owner = msg.sender;
		fomo721Count = 0;
		fomo721PieceCount = 0;
		FomoToken = IERC20(_fomotoken);
		prizePool = burnAddress;

		_F = keccak256(bytes("F")); 
		_o = keccak256(bytes("o")); 
		_m = keccak256(bytes("m")); 
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
    
	function getRandom() internal view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
		uint256 rnd = UniformRandomNumber.uniform(seed, 10000);
		return rnd;
	}

	function getFomo721Count() external view returns (uint256) {
		return fomo721Count;
	}

	function getFomo721PieceCount() external view returns (uint256) {
		return fomo721PieceCount;
	}

	function mintFomo721Piece() external {
		require(msg.sender == tx.origin);
		FomoToken.safeTransferFrom(msg.sender, address(this), mintPieceFee);
		FomoToken.safeTransferFrom(address(this), burnAddress, mintPieceFee.mul(burnRatio).div(1000));
		FomoToken.safeTransferFrom(address(this), prizePool, FomoToken.balanceOf(address(this)));
		uint256 rnd = getRandom();
		string memory char;
		if (rnd >= 9990) {
			// 0.001
			char = "1";
		} else if (rnd >= 9980) {
			// 0.002
			char = "2";
		} else if (rnd >= 9930) {
			// 0.007
			char = "7";
		} else if (rnd >= 9000) {
			// 0.1
			char = "o";
		} else if (rnd >= 8000) {
			// 0.2
			char = "m";
		} else if (rnd >= 4000) {
			// 0.6
			char = "o";
		} else if (rnd >= 1000) {
			// 0.9
			char = "F";
		} else {
			char = "Don't give up, bro!";
		}
		uint256 tokenId = _getNextTokenId();
		tokens[tokenId] = Fomo721Token(tokenId, char);
		fomo721PieceCount += 1;
		_mint(msg.sender, tokenId);
	}

	function check(uint256 id, bytes32 v) internal view returns (bool) {
		Fomo721Token memory token = tokens[id];
		return ownerOf(id) == msg.sender && keccak256(bytes(token.char)) == v;
	}

	function burnIt(uint256 id) external {
		require(ownerOf(id) == msg.sender);
		_burn(id);
	}

	function mintFomo721(uint256 id1, uint256 id2, uint256 id3, uint256 id4, uint256 id5, uint256 id6, uint256 id7) external {
		require(check(id1, _F) && check(id2, _o) && check(id3, _m) && check(id4, _o) && check(id5, _7) && check(id6, _2) && check(id7, _1), "check failed");
		_burn(id1); _burn(id2); _burn(id3); _burn(id4); _burn(id5); _burn(id6); _burn(id7);
		fomo721PieceCount = fomo721PieceCount.sub(7);
		uint256 tokenId = _getNextTokenId();
		tokens[tokenId] = Fomo721Token(tokenId, "Fomo721");
		_mint(msg.sender, tokenId);
		fomo721Count = fomo721Count.add(1);
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
