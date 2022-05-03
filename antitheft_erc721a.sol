// SPDX-License-Identifier: MIT

/** 
          .@@@                                                                  
              ,@@@@@@@&,                  #@@%                                  
                   @@@@@@@@@@@@@@.          @@@@@@@@@                           
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
                                   @@@@@@@    &@@@@@@@@@@@@@@@@@                
                                       @@@/        &@@@@@@@@@@@@@,              
                                           @            @@@@@@@@@@@             
                                                            /@@@@@@@#           
                                                                 @@@@@          
                                                                     *@&   
        RTFKT Studios (https://twitter.com/RTFKT)
        Anti-Theft System (made by @CardilloSamuel)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    REQUIRE : 
        - Change of ERC721A code safeTransferFrom to add contract owner address

            bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
                getApproved(tokenId) == _msgSender() ||
                isApprovedForAll(prevOwnership.addr, _msgSender()) || 
                _msgSender() == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

        - Add override in main code

            function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override(AntiTheft, ERC721A) {
                super._beforeTokenTransfers(from, to, startTokenId, quantity);
            }
            function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override(AntiTheft, ERC721A) {
                super._afterTokenTransfers(from, to, startTokenId, quantity);
            }
**/
        

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
 
abstract contract AntiTheft is ERC721A, Ownable {
    bool useTimelockSystem = true;
    bool blockTransactionWhenFlagged = true;
    bool useBlacklistingSystem = true;
    uint256 public maximumTimeLastTransfer = 86400; // In second (default : 86400 - 24 hours)

    // Using mapping to reduce gas usage
    mapping (address => uint256) public pastOwnerLedger; 
    mapping (uint256 => address) public stolenFlags;
    mapping (address => bool) public blacklistedAddress;
    mapping (address => mapping (address => bool)) public exceptionBlacklist;

    /** 
        CORE CONTRACT 
    **/
    function flagNftAsStolen(uint256 tokenId) public {
        require(_exists(tokenId), "Token doesn't exist");
        require(pastOwnerLedger[msg.sender] != 0, "You never owned that token");
        require(ownerOf(tokenId) != msg.sender, "You can't raise a flag against yourself");
        require(stolenFlags[tokenId] == 0x0000000000000000000000000000000000000000, "A flag has been raised already");
        if(useTimelockSystem) require( (block.timestamp - pastOwnerLedger[msg.sender]) <= maximumTimeLastTransfer, "Time to flag token has been elapsed");

        stolenFlags[tokenId] = msg.sender;
    }

    function toggleStolenFlag(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token doesn't exist");

        stolenFlags[tokenId] = 0x0000000000000000000000000000000000000000;
    }

    function approveStolenFlag(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Token doesn't exist");
        require(stolenFlags[tokenId] != 0x0000000000000000000000000000000000000000, "Token not flagged as stolen");

        blacklistedAddress[ownerOf(tokenId)] = true;
        safeTransferFrom(ownerOf(tokenId), stolenFlags[tokenId], tokenId, "");
        
        stolenFlags[tokenId] = 0x0000000000000000000000000000000000000000;
    }

    function addException(address to) public {
        exceptionBlacklist[msg.sender][to] = true;
    }

    /** 
        ADMINISTRATIVE SYSTEM MANAGEMENT 
    **/ 
    function toggleBlacklistedAddress(address chosenAddress) public onlyOwner {
        require(useBlacklistingSystem, "The blacklisting system is not being used");

        blacklistedAddress[chosenAddress] = !blacklistedAddress[chosenAddress];
    }

    function toggleCoreSystem(string calldata systemName) public onlyOwner {
        if(keccak256(bytes(systemName)) == keccak256(bytes("blacklist"))) useBlacklistingSystem = !useBlacklistingSystem;
        else if(keccak256(bytes(systemName)) == keccak256(bytes("transferBlock"))) blockTransactionWhenFlagged = !blockTransactionWhenFlagged;
        else if(keccak256(bytes(systemName)) == keccak256(bytes("timelock"))) useTimelockSystem = !useTimelockSystem;
        else revert("No system found");
    }

    function modifyMaximumTimeTransfer(uint256 newMaximumTime) public onlyOwner {
        maximumTimeLastTransfer = newMaximumTime;
    }

    /** 
        HOOKING TO ERC STANDARD FUNCTIONS 
    **/
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        if(blockTransactionWhenFlagged) require(stolenFlags[startTokenId] == 0x0000000000000000000000000000000000000000 || msg.sender == owner(), "This NFT has been flagged as stolen and can't be transferred until litige has been set.");
        if(useBlacklistingSystem) require(!blacklistedAddress[to] || exceptionBlacklist[from][to], "This address has been blacklisted and can't receive this token");

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // Hooking to _afterTokenTransfers
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        pastOwnerLedger[to] = block.timestamp; // Admitting past ownership by saying when was the last timestamp of ownership
        exceptionBlacklist[from][to] = false;

        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }
}