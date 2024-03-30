// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./lzApp/NonblockingLzAppUpgradeable.sol";

contract ReleapProfileNFT is ERC721EnumerableUpgradeable, NonblockingLzAppUpgradeable {
    address payable public admin;
    uint256 public totalMints;
    uint256 public mintPrice;
    uint256 private dataStoreIndex;

    mapping(string => bool) public profileNameUsed;

    mapping(string => uint256) public profileNameToTokenId;

    mapping(uint256 => string) public tokenIdToProfileName;

    mapping(uint256 => string) public dataStore;

    event TokenMinted(address indexed to, uint256 tokenId);

    event ProfileCreated(string profileName);

    event LzProfileCreated(string profileName);

    event DataCreated(uint256 tokenId, string data);

    function initialize() initializer public {
        __ERC721_init("ReleapProfile", "RELEAP");
        __NonblockingLzAppUpgradeable_init(0x9b896c0e23220469C7AE69cb4BbAE391eAa4C8da);
        totalMints = 0;
        mintPrice = 0 ether;
        dataStoreIndex = 0;
        admin = payable(msg.sender);
    }

    function createProfileLZ(string memory profileName, uint16 _dstChainId, bytes calldata payload) public payable {
        createProfile(profileName);
        _lzSend(_dstChainId, payload, payable(msg.sender), address(0x0), bytes(""), msg.value);
        emit LzProfileCreated(profileName);
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory) internal override {}

    function safeMint(address to) internal {
        totalMints++;
        _safeMint(to, totalMints);
        emit TokenMinted(to, totalMints);
    }

    function createProfile(string memory profileName) public payable {
        require(mintPrice <= msg.value, "Invalid amount sent");
        require(!profileNameUsed[profileName], "Profile Exists");
        sendValue(admin, address(this).balance);
        profileNameUsed[profileName] = true;
        uint256 newIndex = totalMints + 1;
        profileNameToTokenId[profileName] = newIndex;
        tokenIdToProfileName[newIndex] = profileName;
        safeMint(msg.sender);
        emit ProfileCreated(profileName);
    }

    function getTokenIdFromProfilename(string memory name) public view returns (uint) {
        return (profileNameToTokenId[name]);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function updateMintPrice(uint256 price) public onlyOwner{
        mintPrice = price;
    }

    function getOwnerOfProfileName(string calldata name) public view returns (address){
        uint256 tokenId = profileNameToTokenId[name];
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function getProfileNameByTokenId(uint256 id) public view returns (string memory){
        return tokenIdToProfileName[id];
    }

    function createData(uint256 tokenId, string memory data) public {
        require(msg.sender == ERC721Upgradeable.ownerOf(tokenId), "Not Profile Owner");
        dataStoreIndex++;
        dataStore[dataStoreIndex] = data;
        emit DataCreated(tokenId, data);
    }

    function _msgSender() internal view override(ContextUpgradeable)
      returns (address sender) {
      sender = ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable)
        returns (bytes calldata) {
        return ContextUpgradeable._msgData();
    }

    receive() external payable {
      sendValue(admin, address(this).balance);
    }
}