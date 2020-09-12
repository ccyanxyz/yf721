pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Fomo721Auction {
    using SafeMath for uint256;
    using Address for address;
	using SafeERC20 for IERC20;

    event AuctionCreated(uint256 _index, address _creator, uint256 _tokenId);
    event AuctionBid(uint256 _index, address _bidder, uint256 amount);
    event Claim(uint256 auctionIndex, address claimer);

    enum Status { pending, active, finished }
	IERC20 public FomoToken;
	IERC721 public Fomo721;

    struct Auction {
        uint256 tokenId;
        address creator;
        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
    }
    Auction[] public auctions;

	constructor(address _fomotoken, address _fomo721) public {
		FomoToken = IERC20(_fomotoken);
		Fomo721 = IERC721(_fomo721);
	}

    function createAuction(uint256 _tokenId,
                           uint256 _startPrice,
                           uint256 _startTime,
                           uint256 _duration) public returns (uint256) {

        require(Fomo721.ownerOf(_tokenId) == msg.sender);
		Fomo721.safeTransferFrom(msg.sender, address(this), _tokenId);

        if (_startTime == 0) { _startTime = now; }

        Auction memory auction = Auction({
            creator: msg.sender,
            tokenId: _tokenId,
            startTime: _startTime,
            duration: _duration,
            currentBidAmount: _startPrice,
            currentBidOwner: address(0),
            bidCount: 0
        });
        auctions.push(auction);
		uint256 index = auctions.length - 1;

        emit AuctionCreated(index, auction.creator, auction.tokenId);

        return index;
    }

    function bid(uint256 auctionIndex, uint256 amount) public returns (bool) {
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator != address(0));
        require(isActive(auctionIndex));

        if (amount > auction.currentBidAmount) {
            // we got a better bid. Return tokens to the previous best bidder
            // and register the sender as `currentBidOwner`
            FomoToken.safeTransferFrom(msg.sender, address(this), amount);
            if (auction.currentBidAmount != 0) {
                // return funds to the previuos bidder
                FomoToken.safeTransferFrom(
					address(this),
                    auction.currentBidOwner,
                    auction.currentBidAmount
                );
            }
            // register new bidder
            auction.currentBidAmount = amount;
            auction.currentBidOwner = msg.sender;
            auction.bidCount = auction.bidCount.add(1);

            emit AuctionBid(auctionIndex, msg.sender, amount);
            return true;
        }
        return false;
    }

    function getTotalAuctions() public view returns (uint256) { return auctions.length; }

    function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }

    function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }

    function getStatus(uint256 index) public view returns (Status) {
        Auction storage auction = auctions[index];
        if (now < auction.startTime) {
            return Status.pending;
        } else if (now < auction.startTime.add(auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }

    function getCurrentBidOwner(uint256 auctionIndex) public view returns (address) { return auctions[auctionIndex].currentBidOwner; }

    function getCurrentBidAmount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].currentBidAmount; }

    function getBidCount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].bidCount; }

    function getWinner(uint256 auctionIndex) public view returns (address) {
        require(isFinished(auctionIndex));
		if(auctions[auctionIndex].currentBidOwner == address(0)) {
			return auctions[auctionIndex].creator;
		}
        return auctions[auctionIndex].currentBidOwner;
    }

    function claimFomoToken(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];

        require(auction.creator == msg.sender);
        FomoToken.safeTransferFrom(address(this), auction.creator, auction.currentBidAmount);

        emit Claim(auctionIndex, auction.creator);
    }

    function claimFomo721(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];

        address winner = getWinner(auctionIndex);
        require(winner == msg.sender);

        Fomo721.transferFrom(address(this), winner, auction.tokenId);
        emit Claim(auctionIndex, winner);
    }
}
