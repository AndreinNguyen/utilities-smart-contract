// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library utilities {
    struct COLLECTION {
        uint256 collectionId;
        address collectionOwner;
    }
    struct Order {
        address maker;
        address taker;
        uint256 price;
        uint256 listing_time;
        uint256 expiration_time;
        uint256 NFTId;
        uint256 amount;
        uint256 nonce;
        address payment_token;
    }
      
}