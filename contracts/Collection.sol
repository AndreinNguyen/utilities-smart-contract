// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./library/utilities.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract collection {
    using Counters for Counters.Counter;
    Counters.Counter private _collectionIds;
    address public backend_address;
    mapping(uint256 => utilities.COLLECTION) public collectionIdtoCOLLECTION;
    event SetCollection(bytes, uint256, address);

    event CreateCollection(uint256, address);

    constructor(address _backend_address) {
        backend_address = _backend_address;
    }
    /**
     * @dev Throws if called by any account other than the dev.
     */
    modifier OnlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }
    /**
     * @dev set back end address
     */
    function setBackendAddress(address _backend_address) public OnlyDev {
        backend_address = _backend_address;
    }
    /**
     * @dev create collection on blockchain
     * @param _owner set owner to collection
     */
    function createCollection(address _owner) public OnlyDev {
        _collectionIds.increment();

        collectionIdtoCOLLECTION[_collectionIds.current()] = utilities
            .COLLECTION(_collectionIds.current(), _owner);
        emit CreateCollection(_collectionIds.current(), _owner);
    }
    /**
     * @dev get collection on blockchain
     * @param collectionId use collection id to get collection
     */
    function getCollection(uint256 collectionId)
        public
        view
        returns (utilities.COLLECTION memory)
    {
        return collectionIdtoCOLLECTION[collectionId];
    }
}
