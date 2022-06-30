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
//
//               @@@  @@@  @@@  @@@  @@@        @@@@@@@  @@@  @@@  @@@@@@@   
//               @@@  @@@  @@@@ @@@  @@@       @@@@@@@@  @@@  @@@  @@@@@@@@  
//               @@!  @@@  @@!@!@@@  @@!       !@@       @@!  !@@  @@!  @@@  
//               !@!  @!@  !@!!@!@!  !@!       !@!       !@!  @!!  !@!  @!@  
//               @!@  !@!  @!@ !!@!  @!!       !@!       @!@@!@!   @!@  !@!  
//               !@!  !!!  !@!  !!!  !!!       !!!       !!@!!!    !@!  !!!  
//               !!:  !!!  !!:  !!!  !!:       :!!       !!: :!!   !!:  !!!  
//               :!:  !:!  :!:  !:!   :!:      :!:       :!:  !:!  :!:  !:!  
//               ::::: ::   ::   ::   :: ::::   ::: :::   ::  :::   :::: ::  
//                : :  :   ::    :   : :: : :   :: :: :   :   :::  :: :  :                                                             
//
//         RTFKT Studios - UNLCKD (https://twitter.com/RTFKT)
//         Anti-Theft System (made by @CardilloSamuel)
//         Securable.sol (made by @aurelianoa)
//         Use at your own risk.

pragma solidity 0.8.7;

abstract contract AntiTheftContract {
    function getCoreParameter(string calldata systemName) external view virtual returns(bool);
    function getPastOwnership(address pastOwner) external view virtual returns(uint256);
    function getStolenFlags(uint256 tokenId) external view virtual returns(address);
    function getBlacklistedAddress(address potentialBlacklisted) external view virtual returns(bool);
    function getExceptionList(address from, address to) external view virtual returns(bool);
    function getMaximumTimeLastTransfer() external view virtual returns(uint256);

    function setPastOwnership(address pastOwner) external virtual;
    function setExceptionList(address from, address to) external virtual;
}

abstract contract Securable {
    address private antiTheftSystemAddress = address(0);

    function _changeAntiTheftContract(address newAddress) internal {
        antiTheftSystemAddress = newAddress;
    }

    function getAntiTheftContract() public view returns (address) {
        return antiTheftSystemAddress;
    }

    function _getPastOwnership() internal view returns (uint256) {
        AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);
        return externalContract.getPastOwnership(msg.sender);
    }

    modifier checkIfStolen(address from, address to, uint256 startTokenId, uint256 quantity) {
        require(antiTheftSystemAddress != address(0), "AntiTheft Address cannot be null");

        AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);

        if(externalContract.getCoreParameter("blockTransactionWhenFlagged")) require(externalContract.getStolenFlags(startTokenId) == 0x0000000000000000000000000000000000000000 || msg.sender == antiTheftSystemAddress, "This NFT has been flagged as stolen and can't be transferred until litige has been set.");
        if(externalContract.getCoreParameter("useBlacklistingSystem")) require(!externalContract.getBlacklistedAddress(to) || externalContract.getExceptionList(from,to), "This address has been blacklisted and can't receive this token");
        if(externalContract.getCoreParameter("blockTransactionBetweenExchange")) require(externalContract.getPastOwnership(msg.sender) == 0 || block.timestamp - externalContract.getPastOwnership(msg.sender) >= externalContract.getMaximumTimeLastTransfer(), "You can't transfer this NFT now.");

        _;
    }

    modifier updatePastOwnership(address from, address to, uint256 startTokenId, uint256 quantity) {
        require(antiTheftSystemAddress != address(0), "AntiTheft Address cannot be null");

        AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);

        externalContract.setPastOwnership(to); // Admitting past ownership by saying when was the last timestamp of ownership
        externalContract.setExceptionList(from, to);

        _;
    }  
}