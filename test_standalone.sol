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
//
//         RTFKT Studios - UNLCKD (https://twitter.com/RTFKT)
//         Dummy NFT
//         Use at your own risk. 
//
/// @dev The idea is to avoid coping the _beforeTranfer and _afterTranfer evrytime. This Secuarble.sol is a simple 
/// sdk package that give the hability for the ERC721 to interact with the antitheft_standalone contract
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./Securable.sol";
 
contract TestNFTStandalone is ERC721A, Ownable, Securable {
    string public baseURI = "ipfs://nope/";
 
    constructor () ERC721A("TestNFT", "TestNFT") {
    }

    function changeAntiTheftContract(address newAddress) public onlyOwner {
        _changeAntiTheftContract(newAddress);
    }

    // Mint
    function mint(uint256 quantity) public {
        require(tx.origin == msg.sender, "The caller is another contract");
        _safeMint(msg.sender, quantity); // Minting of the token(s)
    }
 
    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getPastOwnership() public view returns (uint256) {
        return _getPastOwnership();
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual checkIfStolen(from, to, startTokenId, quantity) override {

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual updatePastOwnership(from, to, startTokenId, quantity) override {
        
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }                                                                                                                                                                                                                                                                                
}