// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IKaiKongsFactory {
    function createCollection(
        string memory _name,
        string memory _symbol,
        uint256 _royaltyFee,
        address _royaltyRecipient,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory baseURI_
    ) external;

    function isKaiKongsNFT(address _nft) external view returns (bool);
}
