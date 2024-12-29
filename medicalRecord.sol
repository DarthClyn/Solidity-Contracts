// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract MedicalRecordManagement is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public masterAdmin;
    
    enum UserRole { Unregistered, Admin, Patient }

    struct Admin {
        address adminAddress;
        string name;
        string institution;
        string department;
        string qualification ;
        string adminId;
        uint totalRecords;
    }

    struct Patient {
        address patientAddress;
        string name;
        uint256 age;
        string patientId;
        string phoneNumber;
        uint256[] associatedRecords;
    }

    struct RecordMetadata {
        address adminUploader;
        address patientOwner;
        string documentName;
        uint256 mintTimestamp;
    }

    mapping(address => Admin) private admins;
    mapping(address => Patient) private patients;
    mapping(address => UserRole) private userRoles;
    mapping(string => address) private patientIdToAddress;
    mapping(uint256 => RecordMetadata) private recordMetadata;

    address[] private adminAddresses;

    event AdminAdded(address indexed adminAddress, string name, string department);
    event PatientAdded(address indexed patientAddress, string name, uint256 age);
    event RecordMinted(uint256 indexed tokenId, address indexed patientAddress, string tokenURI);
    event DebugLog(string message, address user); // Debug event

    modifier onlyMasterAdmin() {
        require(msg.sender == masterAdmin, "Only the master admin can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(userRoles[msg.sender] == UserRole.Admin, "Only an admin can call this function");
        _;
    }

    modifier onlyPatient() {
        require(userRoles[msg.sender] == UserRole.Patient, "Only a registered patient can call this function");
        _;
    }

    constructor() ERC721("MedicalRecord", "MR") {
        masterAdmin = payable(msg.sender);
        userRoles[msg.sender] = UserRole.Admin;

        admins[masterAdmin] = Admin({
            adminAddress: masterAdmin,
            name: "Master",
            institution: "Founder",
            department: "All",
            qualification:"Developer",
            adminId: "AD_00",
            totalRecords: 0
        });

        adminAddresses.push(masterAdmin);
        emit AdminAdded(masterAdmin, "Master", "All");
    }

    // Function to add a new admin
    function addAdmin(address adminAddress, string memory name,string memory institute, string memory department, string memory qualification) public onlyMasterAdmin {
        require(userRoles[adminAddress] == UserRole.Unregistered, "Admin already exists or user is registered.");
        
        string memory newAdminId = string(abi.encodePacked("AD_", uint2str(adminAddresses.length + 1)));

        // Add admin details
        admins[adminAddress] = Admin(adminAddress, name, institute,department, qualification,newAdminId,0);
        adminAddresses.push(adminAddress);
        userRoles[adminAddress] = UserRole.Admin;
        
        emit AdminAdded(adminAddress, name, department);
    }

    // Function to add a new patient
    function addPatient(address patientAddress, string memory name, uint256 age, string memory phoneNumber) public onlyAdmin {
        require(userRoles[patientAddress] == UserRole.Unregistered, "Patient already exists or user is registered.");
        
        string memory newPatientId = string(abi.encodePacked("PT_", uint2str(patientCount + 1)));
        patients[patientAddress] = Patient(patientAddress, name, age, newPatientId, phoneNumber, new uint256[] (0));
       
        patientIdToAddress[newPatientId] = patientAddress;
        userRoles[patientAddress] = UserRole.Patient;
         patientCount+=1;
        emit PatientAdded(patientAddress, name, age);
    }

    // Function to mint a new medical record NFT
    function mintRecord(string memory tokenURI, address patientAddress, string memory name) public onlyAdmin returns (uint256) {
        require(userRoles[patientAddress] == UserRole.Patient, "Only a registered patient can own a medical record.");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(patientAddress, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        patients[patientAddress].associatedRecords.push(newTokenId);

        // Add metadata (document name and mint timestamp)
        recordMetadata[newTokenId] = RecordMetadata({
            adminUploader : msg.sender,
            patientOwner: patientAddress,
            documentName: name,  // Using tokenURI as document name here, you can customize it
            mintTimestamp: block.timestamp
        });
        admins[msg.sender].totalRecords += 1;
        recordCount+=1;
        emit RecordMinted(newTokenId, patientAddress, tokenURI);
        return newTokenId;
    }
    function getAdminDetails(address adminAddress) public view returns (
    string memory name,
    string memory institution,
    string memory department,
    string memory adminId,
    string memory qualification,
    uint totalRecords
) {
    require(userRoles[adminAddress] == UserRole.Admin, "Address is not a registered admin.");
    Admin storage admin = admins[adminAddress];
    return (admin.name, admin.institution, admin.department, admin.adminId,admin.qualification, admin.totalRecords);
}


    // Function to get patient details
    function getPatientDetails(address patientAddress) public view returns (string memory name, uint256 age, string memory patientId, string memory phoneNumber) {
        require(userRoles[patientAddress] == UserRole.Patient, "Address is not a registered patient.");
        Patient storage patient = patients[patientAddress];
        return (patient.name, patient.age, patient.patientId, patient.phoneNumber);
    }

    // Function to get a patient's associated records
    function getPatientRecords(address patientAddress) public view returns (uint256[] memory) {
        require(userRoles[patientAddress] == UserRole.Patient, "Address is not a registered patient.");
        return patients[patientAddress].associatedRecords;
    }

    // Function to check if an address is an admin
    function isAdmin(address adminAddress) public view returns (bool) {
        return userRoles[adminAddress] == UserRole.Admin;
    }

    // Function to check if an address is a patient
    function isPatient(address patientAddress) public view returns (bool) {
        return userRoles[patientAddress] == UserRole.Patient;
    }
    function getAdmins() public view returns (Admin[] memory) {
        Admin[] memory allAdmins = new Admin[](adminAddresses.length);
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            allAdmins[i] = admins[adminAddresses[i]];
        }
        return allAdmins;
    }
    uint256 public patientCount;
    uint256 public recordCount;

    function getMetrics() public view returns (uint256 nadmins, uint256 npatients, uint256 records) {
    return (adminAddresses.length, patientCount, recordCount);
}
        // Function to retrieve record metadata by tokenId
    function getRecordMetadata(uint256 tokenId) public view returns (string memory documentName, uint256 mintTimestamp, address owneruploader) {
        require(recordMetadata[tokenId].mintTimestamp != 0, "Token does not exist.");
        RecordMetadata storage metadata = recordMetadata[tokenId];
        return (metadata.documentName, metadata.mintTimestamp , metadata.adminUploader);
    }
    function getUserRole(address user) public view returns (string memory) {
        if (userRoles[user] == UserRole.Admin) {
            return "Admin";
        } else if (userRoles[user] == UserRole.Patient) {
            return "Patient";
        } else {
            return "Unregistered";
        }
    }

    // Utility function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
