// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract IPBlockchainProContract {

    // Data Structures
    enum IPType { Patent, Trademark, Copyright }

    struct IP {
        IPType ipType;
        string id;
        uint initialFilingDate; // Stored as Unix timestamp
        uint publicationDate; // Stored as Unix timestamp
        uint lastRenewalDate; // Stored as Unix timestamp
        uint timesRenewed;
        uint originalExpirationDate; // Stored as Unix timestamp
        uint adjustedExpirationDate; // Stored as Unix timestamp
        bool isRevoked;
        ModificationFiling[] subsequentModificationFilings;
        address[] previousOwners;
        address[] inventors;
    }

    struct ModificationFiling {
        uint dateRenewed; // Stored as Unix timestamp
        uint dateTransferred; // Stored as Unix timestamp
        uint dateRevoked; // Stored as Unix timestamp
    }

    // State variables
    mapping(string => IP) public IPs; // IPID to IP details
    mapping(address => string[]) public userIPs; // User address to list of IPIDs
    address public admin;
    address[] public userAddresses; // Track all user addresses

    // Events
    event IPPublished(string ipId, IPType ipType, address owner);
    event IPTransferred(string ipId, address from, address to);
    event IPExtended(string ipId, uint newExpirationDate);
    event IPRevoked(string ipId);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Constructor
    constructor() {
        admin = msg.sender;
    }

    // Functions

    // MostRecentGasFee (Says how much it'll cost to file)
    function MostRecentGasFee() public view returns (uint) {
        return gasleft();
    }

    // Publish IP
    function publishIP(
        string memory ipId,
        IPType ipType,
        uint initialFilingDate,
        uint publicationDate,
        uint originalExpirationDate,
        address[] memory _inventors
    ) public {
        require(IPs[ipId].originalExpirationDate == 0, "IP already exists");

        IPs[ipId] = IP(
            ipType,
            ipId,
            initialFilingDate,
            publicationDate,
            0,
            0,
            originalExpirationDate,
            originalExpirationDate,
            false,
            new ModificationFiling[](0),
            new address[](0),
            _inventors
        );

        // Add user to the list if not already present
        if (!isUserRegistered(msg.sender)) {
            userAddresses.push(msg.sender);
        }

        userIPs[msg.sender].push(ipId);

        emit IPPublished(ipId, ipType, msg.sender);
    }

    // Search IP (Placeholder for word2vec/AI)
    function searchIP(string memory searchTerm) public view returns (string[] memory) {
        // TODO: Implement word2vec/AI search logic here
        // This is a placeholder, returning an empty array
        return new string[](0);
    }

    // Verify IP
    function verifyIP(string memory ipId) public view returns (bool) {
        return (IPs[ipId].originalExpirationDate != 0 && !IPs[ipId].isRevoked);
    }

    // Transfer IP
    function transferIP(string memory ipId, address newOwner) public {
        require(IPs[ipId].originalExpirationDate != 0, "IP does not exist");
        require(msg.sender == getIPOwner(ipId), "You are not the owner of this IP");

        // TakeTransferFee_FromSeller (set by the Government)
        // +&&TakeIPFee_FromBuyer (depends on the previous action, set by the previous owner)
        // Assume fees are handled off-chain for simplicity

        IPs[ipId].previousOwners.push(getIPOwner(ipId));

        // Update user lists
        userIPs[msg.sender] = removeIPFromUser(msg.sender, ipId);
        userIPs[newOwner].push(ipId);

        // Add new owner to the list if not already present
        if (!isUserRegistered(newOwner)) {
            userAddresses.push(newOwner);
        }

        emit IPTransferred(ipId, msg.sender, newOwner);
    }

    function removeIPFromUser(address user, string memory ipId) private returns (string[] memory) {
        string[] memory newIPList = new string[](userIPs[user].length - 1);
        uint index = 0;
        for (uint i = 0; i < userIPs[user].length; i++) {
            if (keccak256(abi.encodePacked(userIPs[user][i])) != keccak256(abi.encodePacked(ipId))) {
                newIPList[index] = userIPs[user][i];
                index++;
            }
        }
        return newIPList;
    }

    // Start Auction IP (basic implementation)
    function startAuctionIP(string memory ipId) public {
        // TODO: Implement auction logic
    }

    // End Auction IP (basic implementation)
    function endAuctionIP(string memory ipId) public {
        // TODO: Implement auction logic
    }

    // Extend IP
    function extendIP(string memory ipId) public {
        require(IPs[ipId].originalExpirationDate != 0, "IP does not exist");
        require(msg.sender == getIPOwner(ipId), "You are not the owner of this IP");

        // TakeExtensionFee_FromOwner (set by the Government)
        // Assume fees are handled off-chain for simplicity

        IPs[ipId].lastRenewalDate = block.timestamp;
        IPs[ipId].adjustedExpirationDate = block.timestamp + 31536000; // Extend by one year
        IPs[ipId].timesRenewed++;

        emit IPExtended(ipId, IPs[ipId].adjustedExpirationDate);
    }

    // Revoke IP
    function revokeIP(string memory ipId) public onlyAdmin {
        require(IPs[ipId].originalExpirationDate != 0, "IP does not exist");

        IPs[ipId].isRevoked = true;

        emit IPRevoked(ipId);
    }

    // Helper function to get the owner of an IP
    function getIPOwner(string memory ipId) public view returns (address) {
        address currentOwner;
        for (uint i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            string[] storage ipList = userIPs[user];
            for (uint j = 0; j < ipList.length; j++) {
                if (keccak256(abi.encodePacked(ipList[j])) == keccak256(abi.encodePacked(ipId))) {
                    currentOwner = user;
                    return currentOwner;
                }
            }
        }
        return address(0); // Return null address if not found
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
}
