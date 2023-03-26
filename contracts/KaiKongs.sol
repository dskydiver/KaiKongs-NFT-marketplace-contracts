// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title KaiKong NFT
/// @author dskydiver
/// @notice Customizable Royalty NFT
contract KaiKongs is ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 private royaltyFee;
    address private royaltyRecipient;

    uint256 public mintPrice = 15 ether; // to be updated as 15 ether
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;

    string public baseURI;

    event UpdatedRoyaltyFee(uint256 _royaltyFee);

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _royaltyFee,
        address _royaltyRecipient,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory baseURI_
    ) ERC721(_name, _symbol) {
        require(_royaltyFee <= 10000, "can't more than 10 percent");
        require(
            _royaltyRecipient != address(0),
            "The royalty recipient can't be 0 address"
        );
        royaltyFee = _royaltyFee;
        royaltyRecipient = _royaltyRecipient;
        transferOwnership(_owner);
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        require(
            keccak256(abi.encodePacked(getSlice(0, 6, baseURI_))) ==
                keccak256(bytes("ipfs://")),
            "must start with 'ipfs://'"
        );
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public payable {
        require(!paused(), "Contract is paused, please try again later");
        require(amount > 0);
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply);

        if (msg.sender != owner()) {
            require(amount <= 3, "You can only mint 3 at once.");
            require(msg.value >= mintPrice * amount);
        }

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function getRoyaltyFee() external view returns (uint256) {
        return royaltyFee;
    }

    function getRoyaltyRecipient() external view returns (address) {
        return royaltyRecipient;
    }

    function updateRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        require(_royaltyFee <= 10000, "can't more than 10 percent");
        royaltyFee = _royaltyFee;
        emit UpdatedRoyaltyFee(_royaltyFee);
    }

    function getSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) public pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin];
        }
        return string(a);
    }
}
