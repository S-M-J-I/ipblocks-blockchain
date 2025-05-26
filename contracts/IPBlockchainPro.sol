// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract IPBlockchainProContract {
    // Data Structures
    enum IPType {
        Patent,
        Trademark,
        Copyright
    }

    struct IPMetaData {
        uint timesRenewed;
        uint originalExpirationDate; // Stored as Unix timestamp
        uint adjustedExpirationDate; // Stored as Unix timestamp
    }

    struct IP {
        string id;
        IPType ipType;
        string title;
        uint initialFilingDate; // Stored as Unix timestamp
        uint publicationDate; // Stored as Unix timestamp
        uint lastRenewalDate; // Stored as Unix timestamp
        IPMetaData metadata;
        bool isRevoked;
        address[] previousOwners;
        address[] inventors;
        uint256 price;
        string fileHash;
        bool isAuction;
    }

    struct ModificationFiling {
        uint dateRenewed; // Stored as Unix timestamp
        uint dateTransferred; // Stored as Unix timestamp
        uint dateRevoked; // Stored as Unix timestamp
    }

    // State variables
    mapping(string => IP) public IPs; // IPID to IP details
    mapping(string => mapping(uint => ModificationFiling)) public modifications;
    mapping(address => string[]) public userIPs; // User address to list of IPIDs
    mapping(string => address) public ipOwners;
    mapping(string => address) public highestBidders;
    address public admin;
    address[] public userAddresses; // Track all user addresses
    bool private _notEnteredTransferIP = true;

    // Events
    event IPPublished(string ipId, IPType ipType, address owner);
    event IPTransferred(
        string ipId,
        address from,
        address to,
        uint256 price,
        uint256 govtFee
    );
    event IPExtended(string ipId, uint newExpirationDate);
    event IPRevoked(string ipId);
    event IPAuctionStarted(string ipId, uint256 basePrice, address owner);
    event IPBid(string ipId, uint256 price, address bidder);
    event IPAuctionEnded(string ipId, address owner);
    event TransactionPerformanceLogged(
        bytes32 indexed transactionId,
        address sender,
        uint256 initiationTimestamp,
        uint256 completionTimestamp,
        uint256 processingTime
    );

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyOwner(string memory ipId) {
        require(
            IPs[ipId].metadata.originalExpirationDate != 0,
            "IP does not exist"
        );
        require(
            msg.sender == getIPOwner(ipId),
            "You are not the owner of this IP"
        );
        _;
    }

    modifier nonReentrant() {
        require(_notEnteredTransferIP, "Rentry guard");
        _notEnteredTransferIP = false;
        _;
        _notEnteredTransferIP = true;
    }

    // Constructor
    constructor() {
        admin = msg.sender;
    }

    // Functions

    function MostRecentGasFee() public view returns (uint) {
        return gasleft();
    }

    /**
     * @notice Publish an IP on-chain
     * @param ipId The IP ID
     * @param title The IP title
     * @param ipType The IP type [0,1,2]
     * @param initialFilingDate The initial filing date
     * @param publicationDate The publication date
     * @param originalExpirationDate The original expiration date
     * @param fileHash The ipfs file hash
     * @param _inventors The ip title
     */
    function publishIP(
        string memory ipId,
        string memory title,
        IPType ipType,
        uint initialFilingDate,
        uint publicationDate,
        uint originalExpirationDate,
        string memory fileHash,
        address[] memory _inventors
    ) public {
        require(
            IPs[ipId].metadata.originalExpirationDate == 0,
            "IP already exists"
        );
        require(bytes(ipId).length > 0, "ID cannot be empty");
        require(bytes(title).length > 0, "Title cannot be empty");

        IP storage newIP = IPs[ipId];
        newIP.ipType = ipType;
        newIP.id = ipId;
        newIP.title = title;
        newIP.initialFilingDate = initialFilingDate;
        newIP.publicationDate = publicationDate;
        newIP.metadata.originalExpirationDate = originalExpirationDate;
        newIP.metadata.adjustedExpirationDate = originalExpirationDate;
        newIP.isAuction = false;
        newIP.inventors = _inventors;
        newIP.price = 0;
        newIP.fileHash = fileHash;
        // newIP.inAuction = false;

        address sender = msg.sender;
        if (!isUserRegistered(sender)) {
            userAddresses.push(sender);
        }

        userIPs[sender].push(ipId);
        ipOwners[ipId] = sender;

        emit IPPublished(ipId, ipType, sender);
    }

    function getIpById(string memory ipId) public view returns (string memory) {
        return IPs[ipId].title;
    }

    // Search IP (Placeholder for word2vec/AI)
    function searchIP(
        string memory searchTerm
    ) public pure returns (string[] memory) {
        // TODO: Implement word2vec/AI search logic here
        // This is a placeholder, returning an empty array
        searchTerm;
        return new string[](0);
    }

    // Verify IP
    function verifyIP(string memory ipId) public view returns (bool) {
        return (IPs[ipId].metadata.originalExpirationDate != 0 &&
            !IPs[ipId].isRevoked);
    }

    function getIpDetailsById(
        string memory ipId
    )
        public
        view
        returns (
            string memory,
            string memory title,
            address owner,
            uint256 price
        )
    {
        require(!compareString(ipId, ""), "ID cannot be empty");
        require(
            IPs[ipId].metadata.originalExpirationDate != 0 &&
                IPs[ipId].isRevoked == false,
            "IP does not exist"
        );
        title = getIpById(ipId);

        return (ipId, title, getIPOwner(ipId), IPs[ipId].price);
    }

    /**
     * @notice Returns the amount of tokens owned by account
     * @param ipId The address to query the balance of
     * @param governmentAddress The address to query the balance of
     */
    function transferIP(
        string memory ipId,
        address payable governmentAddress
    ) public payable nonReentrant {
        // check
        require(
            IPs[ipId].metadata.originalExpirationDate != 0,
            "IP does not exist"
        );
        require(IPs[ipId].isAuction, "IP not in auction");
        require(msg.sender.balance > msg.value, "Not enough balance in wallet");

        address payable ownerAddress = payable(getIPOwner(ipId));
        require(msg.sender != ownerAddress, "Cannot transfer IP to yourself");

        // TakeTransferFee_FromSeller (set by the Government)
        // +&&TakeIPFee_FromBuyer (depends on the previous action, set by the previous owner)
        uint256 priceToPay = IPs[ipId].price;
        require(
            msg.value >= priceToPay,
            "Insufficient transaction funds for IP transfer"
        );

        // effect
        IPs[ipId].previousOwners.push(ownerAddress);

        // Update user lists
        userIPs[ownerAddress] = removeIPFromUser(ownerAddress, ipId);
        userIPs[msg.sender].push(ipId);

        // Add new owner to the list if not already present
        if (!isUserRegistered(msg.sender)) {
            userAddresses.push(msg.sender);
        }
        ipOwners[ipId] = msg.sender;

        // interactions
        // 20% platform fee to govt
        uint256 governmentFee = (msg.value / 100) * 20;
        require(governmentFee > 0, "Not enough govt fee");

        // rest to seller
        uint256 sellerPayment = msg.value - governmentFee;
        require(sellerPayment > 0, "Not enough seller fee");

        // send fees to government and previous owner
        (bool sentToGovt, ) = governmentAddress.call{value: governmentFee}("");
        require(sentToGovt, "Failed to send fee to government");

        (bool sentToPreviousOwner, ) = ownerAddress.call{value: sellerPayment}(
            ""
        );
        require(sentToPreviousOwner, "Failed to send fee to previous owner");

        emit IPTransferred(
            ipId,
            ownerAddress,
            msg.sender,
            priceToPay,
            governmentFee
        );
    }

    function removeIPFromUser(
        address user,
        string memory ipId
    ) private view returns (string[] memory) {
        string[] memory newIPList = new string[](userIPs[user].length - 1);
        uint index = 0;
        for (uint i = 0; i < userIPs[user].length; i++) {
            if (
                keccak256(abi.encodePacked(userIPs[user][i])) !=
                keccak256(abi.encodePacked(ipId))
            ) {
                newIPList[index] = userIPs[user][i];
                index++;
            }
        }
        return newIPList;
    }

    function startAuctionIP(
        string memory ipId,
        uint256 basePrice
    ) public onlyOwner(ipId) {
        require(basePrice > 0, "Invalid base price: 0/negative");
        require(!IPs[ipId].isAuction, "This IP is already in auction");

        IPs[ipId].price = basePrice;
        IPs[ipId].isAuction = true;

        emit IPAuctionStarted(ipId, basePrice, msg.sender);
    }

    function setIpPrice(string memory ipId, uint256 newPrice) public {
        require(IPs[ipId].isAuction, "This IP is not in auction");
        IPs[ipId].price = newPrice;
        highestBidders[ipId] = msg.sender;

        emit IPBid(ipId, newPrice, msg.sender);
    }

    function endAuctionIP(string memory ipId) public onlyOwner(ipId) {
        require(IPs[ipId].isAuction, "This IP is not in auction");
        IPs[ipId].isAuction = false;

        emit IPAuctionEnded(ipId, msg.sender);
    }

    // Extend IP
    function extendIP(string memory ipId) public {
        require(
            IPs[ipId].metadata.originalExpirationDate != 0,
            "IP does not exist"
        );
        require(
            msg.sender == getIPOwner(ipId),
            "You are not the owner of this IP"
        );

        // TakeExtensionFee_FromOwner (set by the Government)
        // Assume fees are handled off-chain for simplicity

        IPs[ipId].lastRenewalDate = block.timestamp;
        IPs[ipId].metadata.adjustedExpirationDate = block.timestamp + 31536000; // Extend by one year
        IPs[ipId].metadata.timesRenewed++;

        emit IPExtended(ipId, IPs[ipId].metadata.adjustedExpirationDate);
    }

    function revokeIP(string memory ipId) public onlyAdmin {
        require(
            IPs[ipId].metadata.originalExpirationDate != 0,
            "IP does not exist"
        );

        IPs[ipId].isRevoked = true;

        emit IPRevoked(ipId);
    }

    // Helper function to get the owner of an IP
    function getIPOwner(string memory ipId) public view returns (address) {
        return ipOwners[ipId];
    }

    // Helper function to check if a user is already registered
    function isUserRegistered(address user) private view returns (bool) {
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    function addressSet() public view returns (address[] memory) {
        return userAddresses;
    }

    function getIpPrice(
        string memory ipId
    ) public view returns (uint256 price) {
        return IPs[ipId].price;
    }

    function compareString(
        string memory a,
        string memory b
    ) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getAuctionedIPs()
        public
        view
        returns (string[] memory, string[] memory, uint256[] memory)
    {
        uint auctionCount = 0;

        // at first, try to get how many ips are in auction (isAuction = True)
        for (uint i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            string[] storage ipList = userIPs[user];

            for (uint j = 0; j < ipList.length; j++) {
                string memory ipId = ipList[j];
                if (IPs[ipId].isAuction) {
                    auctionCount++;
                }
            }
        }

        // we now need to create an array and store ipids that are auctioned
        string[] memory auctionIPs = new string[](auctionCount);
        uint idx = 0;
        for (uint i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            string[] storage ipList = userIPs[user];

            for (uint j = 0; j < ipList.length; j++) {
                string memory ipId = ipList[j];
                if (IPs[ipId].isAuction) {
                    auctionIPs[idx] = ipList[j];
                    idx++;
                }
            }
        }

        // use the stored ips to save to displayed arrays
        string[] memory ipIds = new string[](auctionIPs.length);
        string[] memory titles = new string[](auctionIPs.length);
        uint256[] memory prices = new uint256[](auctionIPs.length);

        for (uint i = 0; i < auctionIPs.length; i++) {
            string memory ipId = auctionIPs[i];
            IP memory ip = IPs[ipId];
            ipIds[i] = ipId;
            titles[i] = ip.title;
            prices[i] = ip.price;
        }

        return (ipIds, titles, prices);
    }
}
