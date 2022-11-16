// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./libary/utilities.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract collection  {
    using Counters for Counters.Counter;
    Counters.Counter private _collectionIds;
    address public backend_address;
    mapping(uint256 => utilities.COLLECTION) public collectionIdtoCOLLECTION;
    event SetCollection(bytes, uint256, address);

    event CreateCollection(uint256, address);

    constructor(address _backend_address) {
        backend_address = _backend_address;
    }

    modifier OnlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }

    function setBackendAddress(address _backend_address) public OnlyDev {
        backend_address = _backend_address;
    }

    function createCollection(address _owner) public OnlyDev {
        _collectionIds.increment();

        collectionIdtoCOLLECTION[_collectionIds.current()] = utilities
            .COLLECTION(_collectionIds.current(), _owner);
        emit CreateCollection(_collectionIds.current(), _owner);
    }

    function getCollection(uint256 collectionId)
        public
        view
        returns (utilities.COLLECTION memory)
    {
        return collectionIdtoCOLLECTION[collectionId];
    }
}
