# Blockchain Repo of IPBlockchainPro

### Tech stack
* **Solidity**

List of data structures:

NFT-IP

Users
    Admin (IP Arbitrator)
        MySQL
    Buyer/Seller (IP Owner)
        Etherium Wallet
            IPs
                IPID

    IP
        Type: (Patent/Trademark) (what about copyrights? We can't really own them, we can rent them, and multiple people can paralelly rent them like a movie/TV series so it's not easy)
        ID: 
         -  If patent: (Year(4DigitNumber)/ID(7DigitNumber)) (irl there's WIPO ST.16 kind codes for patents, we'll fix that below)
         -  If trademark: (Series(2DigitNumber)/ID(6DigitNumber))
        
        InitialFilingDate: (Year-Month-Day) (Americans don't actually use MM/DD/YYYY except irl)
        PublicationDate: (Year-Month-Day)
        LastRenewalDate: (Year-Month-Day)
        TimesRenewed: (Integer)
        Original_ExpirationDate: (Year-Month-Day)
        Adjusted_ExpirationDate: (Year-Month-Day)  (Patents will forcefully expire after (20 years Utility, 15 years Design, 20 years Plant) whether we like it or not, Trademark can renew forever, e.g. Disney's Mickey Mouse)
        IsRevoked: (Boolean) (What about IsActive, Javascript will figure that out)
        SubsequentModificationFilings:
            {
                Dates_Renewed: (Year-Month-Day)
            Dates_Transfered: (Year-Month-Day)
            Dates_Revoked: (Year-Month-Day)
            }
        PreviousOwners: 
            {
                Owner1, ...
            }
        Inventors:{
            Inventor1, ...
        }




List of functions:
    MostRecentGasFee (Says how much it'll cost to file)
    ApplicationValidity_Test
        SearchAnIP[0] score<=50
    PublishIP
        UpdateChaincode
        +&& UpdateWallet (Depends on update chaincode otherwise fail-before, gas fees are taken here)

    SearchAnIP
        word2vec/AI nonsense
    VerifyAnIP
        CheckIPfromGlobalState (CouchDB?)

    TransferAnIP
        TakeTransferFee_FromSeller (set by the Government, just like Ebay auctions, the Government takes its cut, the seller never excepts 100% of the product prices there too)
        +&&TakeIPFee_FromBuyer (depends on the previous action, set by the previous owner)
        +&&UpdateTheIPItself (depends on the previous action, change owner name, append previous owner name, update timestamps of ownership throughout this IPs lifespan)
    
    StartAuctionAnIP
        BidsManage (give in, retract bids, changing bids means (retract && give in))
          foreach  LockWalletAmountIPFee_FromBuyer (set by the current highest bidder, block that amount on the current highest bidder's wallet, auto retract all previous bids) (reject bids below the lowest (this'll be done in JS))

    EndAuctionAnIP
        TakeAuctionPremiumFee_FromSeller (set by the platform, just like Ebay auctions, our platform's fee)
        TakeTransferFee_FromSeller (set by the Government, just like Ebay auctions, the Government takes its cut, the seller never excepts 100% of the product prices there too)
        +&&UpdateTheIPItself (depends on the previous action, change owner name, append previous owner name, update timestamps of ownership throughout this IPs lifespan)

    ExtendAnIP
        TakeExtensionFee_FromOwner (set by the Government)
        +&&UpdatetTheIPItself (depends on the previous action)
    RevokeAnIP
        +&&UpdateTheIPItself (It's not longer valid now, it has expired, move current owner, to previous owner, update timestamps)
    


