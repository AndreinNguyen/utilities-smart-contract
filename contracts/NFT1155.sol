// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./library/utilities.sol";
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
    /**
     * @dev set DOMAIN_SEPARATOR as EIP-721 standard
     */
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
    /**
     * @dev Throws if called by any account other than the dev.
     */
    modifier onlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }
    /**
     * @dev set MKP contract address
     */
    function setMKPAddress(address _MKPAddress) public onlyDev {
        MKPAddress = _MKPAddress;
    }

    /**
     * @dev mint NFT
     */

    function create1155NFT(
        address _creator,
        string calldata _tokenURI,
        uint256 _amount
    ) public {
        _tokenIds.increment();
        uint256 _newNFTid = _tokenIds.current();
        _mint(_creator, _newNFTid, _amount, "");
        tokenSupply[_newNFTid] = _amount;
        NFTcreators[_newNFTid] = _creator;
        NFTexisted[_newNFTid] = true;
        _setURI(_newNFTid, _tokenURI);
        emit Create1155NFT(_creator, _newNFTid);
    }
    
    /**
     * @dev get NFT creator
     */
    function getNFTcreator(uint256 NFTId)
        public
        view
        virtual
        returns (address)
    {
        return NFTcreators[NFTId];
    }
    /**
     * @dev get NFT total supply
     */
    function totalSupply(uint256 NFTid) public view returns (uint256) {
        require(NFTid <= _tokenIds.current(), "NFT not released");
        return tokenSupply[NFTid];
    }
    /**
     * @dev transfer NFT 
     * @param _signature signature for checking if NFT listed
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _Id,
        uint256 _amount,
        bytes memory _signature
    ) public override{
        require(msg.sender == _from, "transfer from invalid owner");
        require(
            balanceOf(_from, _Id) - IMarketplace(MKPAddress).checkListingAmount(_signature)>= _amount,
            "insufficient balance for transfer"
        );
        _safeTransferFrom(_from, _to, _Id, _amount, "");
        emit Transfer1155NFT(_from, _to, _Id, _amount);
    }
    function transfer1155NFT(
        address _from,
        address _to,
        uint256 _Id,
        uint256 _amount,
        bytes memory _signature
    ) public {
        safeTransferFrom(_from, _to, _Id, _amount, _signature);
    }
    /**
     * @dev Approve all NFT 1155 
     */
    function approveAll1155NFT(
        address _owner,
        address _operator,
        bool _approved
    ) public {
        require(msg.sender == _owner, "approve from invalid owner");
        _setApprovalForAll(_owner, _operator, _approved);
        emit ApproveAll1155NFT(_owner, _operator, _approved);
    }
    /**
     * @dev permit function base on EIP-2612
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _NFTId,
        uint256 _price,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public returns (bool) {
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address _owner,address _spender,uint256 _NFTId,uint256 _price)"
                ),
                _owner,
                _spender,
                _NFTId,
                _price
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
    /**
     * @dev transfer function for buy function in marketplace.
     * @param _signature signature from NFT owner
     * @param _nonce NFT owner's nonce,
     */
    function transferWithPermission(
        address _from,
        address _to,
        uint256 _NFTId,
        uint256 _amount,
        uint256 _price,
        uint256 _nonce,
        bytes calldata _signature
    ) public virtual override returns (bool) {
        require(
            IMarketplace(MKPAddress).checkListingAmount(_signature) >=0 ,
            "NFT not Listed"
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = _splitSignature(_signature);
        require(
            permit(_from, address(this), _NFTId, _price, _nonce, v, r, s),
            "not permitted"
        );
        _safeTransferFrom(_from, _to, _NFTId, _amount, "");
        emit TransferWithPermission(_from, _to, _NFTId, _amount);
        return true;
    }
    /** 
    * @dev for back_end get nonce from smart contract.
     * @param _owner address to get the nonce
     */
    function getNonce(address _owner) public view onlyDev returns (uint256) {
        return nonces[_owner];
    }
    /**
     * @dev split signature to v, r, s form.
     * @param _signature signature in bytes form
     */
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
