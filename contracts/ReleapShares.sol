// SPDX-License-Identifier: MIT 
import "./lzApp/NonblockingLzAppUpgradeable.sol";
import "hardhat/console.sol";
import "./StargateComposed.sol";
import "./interfaces/IStargateComposer.sol";
import "./interfaces/IStargateReceiver.sol";

// File: contracts/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/ReleapShares.sol

pragma solidity >=0.8.2 <0.9.0;

contract ReleapShares is IStargateReceiver, Initializable, Ownable {
    using SafeMath for uint;

    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;

    address public stargateRouter;      // an IStargateRouter instance

    function initialize(address _stargateAddress) initializer public {
        stargateRouter = _stargateAddress;
    }
    
    event Trade(address trader, address subject, bool isBuy, uint256 shareAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    //Store userData
    mapping(address => string) public userData;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    function updateUserData(string memory _uri) public {
        userData[msg.sender] = _uri;
    }

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 ) * (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 250000;
    }

    function getBuyPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], amount);
    }

    function getSellPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price - protocolFee - subjectFee;
    }

    function buyShares(address sharesSubject, address recipient, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        // require(supply > 0 || sharesSubject == msg.sender, "Only the shares' subject can buy the first share");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        sharesBalance[sharesSubject][recipient] = sharesBalance[sharesSubject][recipient] + amount;
        sharesSupply[sharesSubject] = supply + amount;
        emit Trade(recipient, sharesSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellShares(address sharesSubject, address recipient, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        // require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(sharesBalance[sharesSubject][recipient] >= amount, "Insufficient shares");
        sharesBalance[sharesSubject][recipient] = sharesBalance[sharesSubject][recipient] - amount;
        sharesSupply[sharesSubject] = supply - amount;
        emit Trade(recipient, sharesSubject, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = recipient.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function lzBuyv2(
        uint16 chainId, 
        uint256 _amountLD,
        uint256 _minAmountLD,        
        bytes calldata _toAddress,
        IStargateComposer.lzTxObj memory _lzTxParams,
        address sharesSubject, 
        uint256 amount 
    ) external payable {

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory _payload;
        {
            _payload = abi.encode(sharesSubject, amount, true);
        }

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateComposer(stargateRouter).swap{value:msg.value}(
            chainId, // destination Stargate chainId
            13,
            13,
            payable(msg.sender), // refund additional messageFee to this address
            _amountLD,
            _minAmountLD,
            _lzTxParams, // the LZ tx params
            _toAddress,
            _payload // the payload to send to the destination
        );
    }

      //-----------------------------------------------------------------------------------------------------------------------
    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    function sgReceive(uint16 /*_chainId*/, bytes memory /*_srcAddress*/, uint /*_nonce*/, address _token, uint amountLD, bytes memory payload) override external {
        require(msg.sender == address(stargateRouter), "only stargate router can call sgReceive!");

        (bytes memory _to, address sender, bytes memory receivingPayload) = abi.decode(payload, (bytes, address, bytes));

        (address sharesSubject, uint amount, bool isBuy) = abi.decode(receivingPayload, (address, uint, bool));

        if (isBuy){
            console.log('Buy instruction');
            buyShares(sharesSubject, sender, amount);
        } else {
            console.log('Sell instruction');
            sellShares(sharesSubject, sender, amount);
        }

    }
}