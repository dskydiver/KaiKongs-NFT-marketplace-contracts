// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IKaiKongsNFT {
    function getRoyaltyFee() external view returns (uint256);

    function getRoyaltyRecipient() external view returns (address);
}
