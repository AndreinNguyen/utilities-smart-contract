// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libary/utilities.sol";
import "./ISVC.sol";
import "./INFT1155.sol";

pragma solidity ^0.8.7;

contract Marketplace {
    address public backend_address;
    address public NFT1155Address;
    address payable public FeeRecipientAddress;
    uint256 public creator_fee;
    uint256 public system_fee;
    mapping(address => uint256) nonces;
    mapping(bytes20 => uint256) public isListed;
    event Listing(bytes20 signature, bool isListed);
    event CancelListing(bytes20 signature, bool isListed);
    event AtomicMatch(
        address maker,
        address taker,
        uint256 NFTId,
        uint256 amount,
        uint256 price,
        bool bestMatch
    );

    constructor(
        address _backend_address,
        address _NFT1155Address,
        address payable _FeeRecipientAddress,
        uint256 _creator_fee,
        uint256 _system_fee
    ) {
        backend_address = _backend_address;
        NFT1155Address = _NFT1155Address;
        FeeRecipientAddress = _FeeRecipientAddress;
        creator_fee = _creator_fee;
        system_fee = _system_fee;
    }

    modifier onlyDev() {
        require(msg.sender == backend_address, "invalid dev address");
        _;
    }

    function setNFT1155Address(address _NFT1155Address) public onlyDev {
        NFT1155Address = _NFT1155Address;
    }

    function setCreatorFee(uint8 _creator_fee) public onlyDev {
        creator_fee = _creator_fee;
    }

    function setSystemFee(uint8 _system_fee) public onlyDev {
        system_fee = _system_fee;
    }

    function listing(bytes calldata _signature, uint256 _amount) public onlyDev {
        require(_signature.length == 65, "signature length invalid");
        isListed[ripemd160(_signature)] = _amount;
        emit Listing(ripemd160(_signature), true);
    }

    function checkListed(bytes calldata _signature)
        public
        view
        virtual
        returns (bool)
    {
        bool isNFTListed = isListed[ripemd160(_signature)] == 0 ? false :true;
        return isNFTListed;
    }

    function cancelListing(bytes calldata _signature) public {
        require(_signature.length == 65, "signature length invalid");
        delete isListed[ripemd160(_signature)];
        emit CancelListing(ripemd160(_signature), false);
    }

    function _orderCanMatch(
        utilities.Order memory _sell,
        utilities.Order memory _buy
    ) internal pure returns (bool) {
        return ((_sell.maker == _buy.taker) &&
            (_sell.taker == _buy.maker) &&
            (_sell.price == _buy.price) &&
            (_sell.listing_time <= _buy.listing_time) &&
            (_sell.expiration_time >= _buy.expiration_time) &&
            (_sell.NFTId == _buy.NFTId) &&
            (_sell.amount == _buy.amount) &&
            (_sell.nonce == _buy.nonce) &&
            (_sell.payment_token == _buy.payment_token));
    }

    function _transferToken(
        address _buyer,
        address _payment_token,
        address payable _NFT_creator,
        address payable _seller,
        uint256 _price
    ) internal returns (bool) {
        if (_payment_token != address(0)) {
            uint256 amountToSystem = (_price * system_fee) / 100 ether;
            uint256 amountToCreator = (_price * creator_fee) / 100 ether;
            uint256 amountToSeller = _price - amountToSystem - amountToCreator;

            ISVC(_payment_token).transferFrom(_buyer, _seller, amountToSeller);
            ISVC(_payment_token).transferFrom(
                _buyer,
                _NFT_creator,
                amountToCreator
            );
            ISVC(_payment_token).transferFrom(
                _buyer,
                FeeRecipientAddress,
                amountToSystem
            );
        } else {
            uint256 amountToSystem = (_price * system_fee) / 100 ether;
            uint256 amountToCreator = (_price * creator_fee) / 100 ether;
            uint256 amounToSeller = _price - amountToSystem - amountToCreator;

            require(msg.value >= _price, "insufficient native token");
            _seller.transfer(amounToSeller);
            _NFT_creator.transfer(amountToCreator);
            FeeRecipientAddress.transfer(amountToSystem);
        }
        return true;
    }
    
    function _atomicMatch(
        utilities.Order memory _sell,
        utilities.Order memory _buy,
        bytes calldata _signature
    ) internal {
        require(checkListed(_signature), "not listed");
        require(_orderCanMatch(_sell, _buy), "Order not matching");
        require(isListed[ripemd160(_signature)] > _sell.amount , "invalid amount");
        if(isListed[ripemd160(_signature)] - _sell.amount >0){
            isListed[ripemd160(_signature)] =  isListed[ripemd160(_signature)] - _sell.amount;
        }
        else{
            delete isListed[ripemd160(_signature)];
        }
        
        require(
            INFT1155(NFT1155Address).transferWithPermission(
                _sell.maker,
                _sell.taker,
                _sell.NFTId,
                _sell.amount,
                _sell.nonce,
                _signature
            ),
            "transfer NFT fail"
        );
        require(
            _transferToken(
                _sell.taker,
                _sell.payment_token,
                payable(INFT1155(NFT1155Address).getNFTcreator(_sell.NFTId)),
                payable(_sell.maker),
                _sell.price
            )
        );
        
        emit AtomicMatch(
            _sell.maker,
            _sell.taker,
            _sell.NFTId,
            _sell.amount,
            _sell.price,
            true
        );
    }

    function atomicMatch(
        address[6] calldata _addrs,
        uint256[12] calldata _uints,
        bytes calldata _signature
    ) public payable {
        _atomicMatch(
            utilities.Order(
                _addrs[0],
                _addrs[1],
                _uints[0],
                _uints[1],
                _uints[2],
                _uints[3],
                _uints[4],
                _uints[5],
                _addrs[2]
            ),
            utilities.Order(
                _addrs[3],
                _addrs[4],
                _uints[6],
                _uints[7],
                _uints[8],
                _uints[9],
                _uints[10],
                _uints[11],
                _addrs[5]
            ),
            _signature
        );
    }
}
