pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IYF721Piece is IERC721 {
    function mint(address to) external;
    function burn(uint256 id) external;
}
