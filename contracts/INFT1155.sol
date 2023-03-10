// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface INFT1155{
    function transferWithPermission(
        address _from,
        address _to,
        uint256 _NFTId,
        uint256 _amount,
        uint256 _price,
        uint256 _nonce,
        bytes calldata _signature
    ) external returns(bool);
    function getNFTcreator(uint256 NFTId) external view returns(address);

}
