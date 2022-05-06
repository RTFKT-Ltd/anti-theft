// SPDX-License-Identifier: MIT

// 
//          .@@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         Anti-Theft System (made by @CardilloSamuel)

//     %%%%%%%%%%%%%%%%%%%%%%%%%% STANDALONE VERSION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//     REQUIRE : 
//         - Change of ERC721A code safeTransferFrom to add contract owner address
//             bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
//                 getApproved(tokenId) == _msgSender() ||
//                 isApprovedForAll(prevOwnership.addr, _msgSender()) || 
//                 _msgSender() == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

//         - Add override in main code
//             function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
//                 AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);

//                 if(externalContract.getCoreParameter("transferBlock")) require(externalContract.getStolenFlags(startTokenId) == 0x0000000000000000000000000000000000000000 || msg.sender == antiTheftSystemAddress, "This NFT has been flagged as stolen and can't be transferred until litige has been set.");
//                 if(externalContract.getCoreParameter("blacklist")) require(!externalContract.getBlacklistedAddress(to) || externalContract.getExceptionList(from,to), "This address has been blacklisted and can't receive this token");
//                 if(externalContract.getCoreParameter("timelock")) require(externalContract.getPastOwnership(msg.sender) == 0 || block.timestamp - externalContract.getPastOwnership(msg.sender) >= externalContract.getMaximumTimeLastTransfer(), "You can't transfer this NFT now.");

//                 super._beforeTokenTransfers(from, to, startTokenId, quantity);
//             }

//             function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
//                 AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);

//                 externalContract.setPastOwnership(to); // Admitting past ownership by saying when was the last timestamp of ownership
//                 externalContract.setExceptionList(from, to);

//                 super._afterTokenTransfers(from, to, startTokenId, quantity);
//             }  

//         - Add the abstract contract
//             abstract contract AntiTheftContract {
//                 function getCoreParameter(string calldata systemName) external view virtual returns(bool);
//                 function getPastOwnership(address pastOwner) external view virtual returns(uint256);
//                 function getStolenFlags(uint256 tokenId) external view virtual returns(address);
//                 function getBlacklistedAddress(address potentialBlacklisted) external view virtual returns(bool);
//                 function getExceptionList(address from, address to) external view virtual returns(bool);
//                 function getMaximumTimeLastTransfer() external view virtual returns(uint256);

//                 function setPastOwnership(address pastOwner) external virtual;
//                 function setExceptionList(address from, address to) external virtual;
//             }

//         - Add the authorized contract system
//             address antiTheftSystemAddress = 0x0fC5025C764cE34df352757e82f7B5c4Df39A836;


//             function changeAntiTheftContract(address newAddress) public onlyOwner {
//                  antiTheftSystemAddress = newAddress;
//             }

abstract contract externalContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual;
}

pragma solidity 0.8.7;
 
contract AntiTheftStandalone {
    bool public blockTransactionBetweenExchange = true;
    bool public blockTransactionWhenFlagged = true;
    bool public useBlacklistingSystem = true;
    uint256 public maximumTimeLastTransfer = 1800; // In second (default : 1800 - 30 minutes)

    // Using mapping to reduce gas usage
    mapping (address => bool) public authorizedContract;
    mapping (address => bool) public blacklistedAddress;
    mapping (address => bool) public authorizedAuthorities;
    mapping (address => mapping(address => uint256)) public pastOwnerLedger; 
    mapping (address => mapping(uint256 => address)) public stolenFlags;
    mapping (address => mapping (address => bool)) public exceptionBlacklist;

    constructor() {
        authorizedAuthorities[msg.sender] = true;
    }

    /** 
        MODIFIERS
    **/

    modifier isAuthorizerAuthority() {
        require(authorizedAuthorities[msg.sender], "You are not authorized to do this");
        _;
    }

    modifier isAuthorizedContract() {
        require(authorizedContract[msg.sender], "Contract is not authorized for this call");
        _;
    }


    /** 
        CORE CONTRACT 
    **/
    function flagNftAsStolen(address contractAddress, uint256 tokenId) public {
        require(pastOwnerLedger[contractAddress][msg.sender] != 0, "You never owned that token");
        externalContract externalToken = externalContract(contractAddress);
        require(externalToken.ownerOf(tokenId) != msg.sender, "You can't raise a flag against yourself");
        require(stolenFlags[contractAddress][tokenId] == 0x0000000000000000000000000000000000000000, "A flag has been raised already");
        if(blockTransactionBetweenExchange) require( (block.timestamp - pastOwnerLedger[contractAddress][msg.sender]) <= maximumTimeLastTransfer, "Time to flag token has been elapsed");

        stolenFlags[contractAddress][tokenId] = msg.sender;
    }

    function toggleStolenFlag(address contractAddress, uint256 tokenId) public isAuthorizerAuthority {
        stolenFlags[contractAddress][tokenId] = 0x0000000000000000000000000000000000000000;
    }

    function approveStolenFlag(address contractAddress, uint256 tokenId) public isAuthorizerAuthority {
        require(stolenFlags[contractAddress][tokenId] != 0x0000000000000000000000000000000000000000, "Token not flagged as stolen");

        externalContract externalToken = externalContract(contractAddress);
        address ownerOfToken = externalToken.ownerOf(tokenId);
        blacklistedAddress[ownerOfToken] = true;
        externalToken.safeTransferFrom(ownerOfToken, stolenFlags[contractAddress][tokenId], tokenId);
        
        stolenFlags[contractAddress][tokenId] = 0x0000000000000000000000000000000000000000;
    }

    function addException(address to) public {
        exceptionBlacklist[msg.sender][to] = true;
    }

    /** 
        ADMINISTRATIVE SYSTEM MANAGEMENT 
    **/ 
    function toggleAuthorizedContract(address contractAddress) public isAuthorizerAuthority {
        authorizedContract[contractAddress] = !authorizedContract[contractAddress];
    }

    function toggleBlacklistedAddress(address chosenAddress) public isAuthorizerAuthority {
        require(useBlacklistingSystem, "The blacklisting system is not being used");

        blacklistedAddress[chosenAddress] = !blacklistedAddress[chosenAddress];
    }

    function toggleCoreSystem(string calldata systemName) public isAuthorizerAuthority {
        if(keccak256(bytes(systemName)) == keccak256(bytes("blacklist"))) useBlacklistingSystem = !useBlacklistingSystem;
        else if(keccak256(bytes(systemName)) == keccak256(bytes("transferBlock"))) blockTransactionWhenFlagged = !blockTransactionWhenFlagged;
        else if(keccak256(bytes(systemName)) == keccak256(bytes("timelock"))) blockTransactionBetweenExchange = !blockTransactionBetweenExchange;
        else revert("No system found");
    }

    function modifyMaximumTimeTransfer(uint256 newMaximumTime) public isAuthorizerAuthority {
        maximumTimeLastTransfer = newMaximumTime;
    }

    /** 
        GETTER FUNCTIONS FOR EXTERNAL CONTRACT 
    **/ 

    function getCoreParameter(string calldata systemName) external view returns(bool) {
        if(keccak256(bytes(systemName)) == keccak256(bytes("blacklist"))) return useBlacklistingSystem;
        else if(keccak256(bytes(systemName)) == keccak256(bytes("transferBlock"))) return blockTransactionWhenFlagged;
        else if(keccak256(bytes(systemName)) == keccak256(bytes("timelock"))) return blockTransactionBetweenExchange;
        else revert("No system found");
    }

    function getPastOwnership(address pastOwner) external view returns(uint256) {
        return pastOwnerLedger[msg.sender][pastOwner];
    }

    function getStolenFlags(uint256 tokenId) external view returns(address) {
        return stolenFlags[msg.sender][tokenId];
    }

    function getBlacklistedAddress(address potentialBlacklisted) external view returns(bool) {
        return blacklistedAddress[potentialBlacklisted];
    }    

    function getExceptionList(address from, address to) external view returns(bool) {
        return exceptionBlacklist[from][to];
    }

    function getMaximumTimeLastTransfer() external view returns(uint256) {
        return maximumTimeLastTransfer;
    }

    /** 
        SETTER FUNCTIONS FOR EXTERNAL CONTRACT 
    **/ 

    function setPastOwnership(address pastOwner) external isAuthorizedContract {
        pastOwnerLedger[msg.sender][pastOwner] = block.timestamp;
    }
    
    function setExceptionList(address from, address to) external isAuthorizedContract {
        exceptionBlacklist[from][to] = false;
    }  
}