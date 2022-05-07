# The AntiTheft System 🥷
### by Samuel Cardillo

DISCLAIMER : This code is still a WORK IN PROGRESS. It has been developed for ERC-721A support for now. We are counting on the community to help us define the future of this system and see if it is something worth building on. Let's build 🛠 🌐

CHECK THE [ISSUES](https://github.com/RTFKT-Ltd/anti-theft/issues) SECTION TO CONTRIBUTE TO THE PROJECT 

## How did it start

The more the NFT ecosystem grows, the more it becomes apparent that scammers are adapting & that the current implementation of NFTs is not. There is a lack of existing securities to protect collectors. How many DMs have I received from our own holders, asking me for help, because their entire NFTs were siphoned by a scammer just because they miss clicked, and for me to be unable to help them out. 

From that point onwards, I decided to try finding a solution to start enabling an anti-theft system. 

It is important to note that the current version of the anti-theft system is only a proposal to the NFT community. It is a matter of fine-tuning and improvement, and it is why it has been made open-source & not kept private. My goal, the goal of RTFKT, is to give the community of builders and collectors, a way of feeling safer. 

**_In a way, the system is like an escrow system where the escrow is the blockchain itself, not a third party account._**

`Before anything, it is important to note that EVERY parameter can be modified by the anti-theft contract deployer, allowing full flexibility over how things works and therefore allowing the community to help fine-tune the experience. `

## How does it work (the non-technical)

When your NFT is transferred (sold, sent to another wallet, ...), it gets locked for a certain amount of time (by default 30 mins) meaning that it can't be transferred for that amount of time. Within that amount of time, you have the ability to raise a flag that your NFT got stolen which block the NFT to be transferred (that can also be disabled) for an undefined amount of time. 

It requires the community and/or the creator of the collection to approve the raised flag, which then transfer the NFT back to the initial wallet. Once that is done, the address that received the NFT wallet initially (that is also another thing that can be disabled or enabled) becomes blacklisted and any NFTs within that wallet blacklisted become frozen and no other NFT from that collection can be transferred to that wallet. 

The contract deployer has the ability to disprove the flag (meaning the NFT becomes unfrozen) and also add or remove a wallet in the blacklist.

## How does it work (the technical)

The collection contract needs to call the anti-theft contract as a middleware. The anti-theft contract can manage multiple collections at once, meaning it can work for your unique collection OR for a company such as RTFKT or YugaLabs. 

A super of the **_beforeTokenTransfer** and **_afterTokenTransfer** hooks needs to be done, those are calling the anti-theft contract which then check which parameters are enabled & perform security checks. Once the token has been transferred, the new former holder and the new one get an updated timestamp, which is used for the time lock functionalities. 

## Things to do : 

* Add tokenId to pastOwnershipLedger to avoid vector of attack where the user can just trade another NFT and reset the time lock
* Change the approve flag so it can be sent back to any address (not sure about that one)
* Create a way for individually activating or not the timelock period - protection logic need be designed to avoid a potential hacker to just bypass the ATS.
