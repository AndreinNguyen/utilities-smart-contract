// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libary/utilities.sol";
import "./INFT1155.sol";
import "./IMarketplace.sol";

contract NFT_1155 is ERC1155, ERC1155URIStorage, INFT1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public backend_address;
    address public MKPAddress;
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => uint256) private nonces;
    mapping(address => mapping(address => uint256)) public approval;
    mapping(uint256 => address) public NFTcreators;
    mapping(uint256 => bool) public NFTexisted;
    event Create1155NFT(address, uint256);
    event ApproveAll1155NFT(address, address, bool);
    event TransferBatch1155NFT(address, address, uint256[], uint256[]);
    event Transfer1155NFT(address, address, uint256, uint256);
    event TransferWithPermission(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    );

    constructor(string memory NFT_URI, address _backend_address)
        ERC1155(NFT_URI)
    {
        backend_address = _backend_address;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("permission")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier onlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }

    function setMKPAddress(address _MKPAddress) public onlyDev {
        MKPAddress = _MKPAddress;
    }

    //mint NFTs, set NFT URI
    //return NFT id
    
    function getNFTstatus(uint256 NFTId) public virtual override returns(bool)  {
        return NFTexisted[NFTId];
        
    }
    function create1155NFT(
        address _creator,
        uint256 _newNFTid,
        uint256 _amount
    ) public virtual override {
        require(!NFTexisted[_newNFTid], "NFT existed");
        _mint(_creator, _newNFTid, _amount, "");
        
        tokenSupply[_newNFTid] = _amount;
        NFTcreators[_newNFTid] = _creator;
        NFTexisted[_newNFTid] = true;
        emit Create1155NFT(_creator, _newNFTid);
    }
    function setNFTURI(uint256 _newNFTid, string calldata _tokenURI) public onlyDev{
        _setURI(_newNFTid, _tokenURI);
    }
    function getNFTcreator(uint256 NFTId)
        public
        view
        virtual
        returns (address)
    {
        return NFTcreators[NFTId];
    }

    function totalSupply(uint256 NFTid) public view returns (uint256) {
        require(NFTid <= _tokenIds.current(), "NFT not released");
        return tokenSupply[NFTid];
    }

    function transfer1155NFT(
        address _from,
        address _to,
        uint256 _Id,
        uint256 _amount,
        bytes memory _signature
    ) public {
        require(msg.sender == _from, "transfer from invalid owner");
        require(
            !IMarketplace(MKPAddress).checkListed(_signature),
            "NFT Listed"
        );
        _safeTransferFrom(_from, _to, _Id, _amount, "");
        emit Transfer1155NFT(_from, _to, _Id, _amount);
    }

    function approveAll1155NFT(
        address _owner,
        address _operator,
        bool _approved
    ) public {
        require(msg.sender == _owner, "approve from invalid owner");
        _setApprovalForAll(_owner, _operator, _approved);
        emit ApproveAll1155NFT(_owner, _operator, _approved);
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _NFTId,
        uint256 _amount,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public returns (bool) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address _owner,address _spender,uint256 _NFTId,uint256 _amount,uint256 _nonce)"
                ),
                _owner,
                _spender,
                _NFTId,
                _amount,
                _nonce
            )
        );

        bytes32 EIP721hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );

        require(_owner != address(0), "invalid address");
        require(_owner == ecrecover(EIP721hash, _v, _r, _s), "invalid owner");
        require(_nonce == nonces[_owner]++, "Invalid nonce");

        approval[_owner][_spender] = _NFTId;
        return true;
    }

    function transferWithPermission(
        address _from,
        address _to,
        uint256 _NFTId,
        uint256 _amount,
        uint256 _nonce,
        bytes calldata _signature
    ) public virtual override returns (bool) {
        require(
            !IMarketplace(MKPAddress).checkListed(_signature),
            "NFT not Listed"
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = _splitSignature(_signature);
        require(
            permit(_from, address(this), _NFTId, _amount, _nonce, v, r, s),
            "not permitted"
        );
        _safeTransferFrom(_from, _to, _NFTId, _amount, "");
        emit TransferWithPermission(_from, _to, _NFTId, _amount);
        return true;
    }

    function getNonce(address _owner) public view onlyDev returns (uint256) {
        return nonces[_owner];
    }

    function _splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(_signature.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(_signature, 32))
            // second 32 bytes.
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(_signature, 96)))
        }
        return (v, r, s);
    }
}
