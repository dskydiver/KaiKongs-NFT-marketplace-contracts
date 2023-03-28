// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./KaiKongs.sol";

/// @title KaiKongs Factory
/// @author dskydiver
/// @notice users can create new collections
contract KaiKongsFactory {
    mapping(address => address[]) public nfts;

    mapping(address => bool) private _KaikongsNFT;

    event CreatedNFTCollection(address indexed creator, address indexed nft);

    function createCollection(
        string memory _name,
        string memory _symbol,
        uint256 _royaltyFee,
        address _royaltyRecipient,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory baseURI_
    ) external {
        KaiKongs nft = new KaiKongs(
            _name,
            _symbol,
            msg.sender,
            _royaltyFee,
            _royaltyRecipient,
            _mintPrice,
            _maxSupply,
            baseURI_
        );

        nfts[msg.sender].push(address(nft));
        _KaikongsNFT[address(nft)] = true;
        emit CreatedNFTCollection(msg.sender, address(nft));
    }

    function importCollection(address _address) external {
        nfts[msg.sender].push(_address);
        _KaikongsNFT[_address] = true;
        emit CreatedNFTCollection(msg.sender, _address);
    }

    function getUserCollections(
        address account
    ) external view returns (address[] memory) {
        return nfts[account];
    }

    function isKaiKongsNFT(address _nft) external view returns (bool) {
        return _KaikongsNFT[_nft];
    }
}
