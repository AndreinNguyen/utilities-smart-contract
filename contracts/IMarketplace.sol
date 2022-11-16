// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IMarketplace{
    function checkListed(bytes memory _signature) external view returns(bool);
}
