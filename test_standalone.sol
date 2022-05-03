// SPDX-License-Identifier: MIT
// Contract audited and reviewed by @CardilloSamuel 
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
 
 abstract contract AntiTheftContract {
    function getCoreParameter(string calldata systemName) external view virtual returns(bool);
    function getPastOwnership(address pastOwner) external view virtual returns(uint256);
    function getStolenFlags(uint256 tokenId) external view virtual returns(address);
    function getBlacklistedAddress(address potentialBlacklisted) external view virtual returns(bool);
    function getExceptionList(address from, address to) external view virtual returns(bool);

    function setPastOwnership(address pastOwner) external virtual;
    function setExceptionList(address from, address to) external virtual;
}


contract TestNFTStandalone is ERC721A, Ownable {
    string public baseURI = "ipfs://nope/";
    address antiTheftSystemAddress = 0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D;
 
    constructor () ERC721A("TestNFT", "TestNFT", 20) {
    }

    function changeAntiTheftContract(address newAddress) public onlyOwner {
        antiTheftSystemAddress = newAddress;
    }
 
    // Mint
    function mint(uint256 quantity) public {
        require(tx.origin == msg.sender, "The caller is another contract");
        _safeMint(msg.sender, quantity); // Minting of the token(s)
    }

    function contractMint() public {
        _safeMint(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 1);
    }

    function contractTransfer() public {
        safeTransferFrom(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0);
    }
 
    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);

        if(externalContract.getCoreParameter("transferBlock")) require(externalContract.getStolenFlags(startTokenId) == 0x0000000000000000000000000000000000000000 || msg.sender == antiTheftSystemAddress, "This NFT has been flagged as stolen and can't be transferred until litige has been set.");
        if(externalContract.getCoreParameter("blacklist")) require(!externalContract.getBlacklistedAddress(to) || externalContract.getExceptionList(from,to), "This address has been blacklisted and can't receive this token");

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        AntiTheftContract externalContract = AntiTheftContract(antiTheftSystemAddress);

        externalContract.setPastOwnership(to); // Admitting past ownership by saying when was the last timestamp of ownership
        externalContract.setExceptionList(from, to);

        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }                                                                                                                                                                                                                                                                                
}