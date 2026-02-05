// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Profiling {
    address public owner;
    
    struct Profile {
        string name;
        string key;
        bool exists;
    }
    
    mapping(address => Profile) public profiles;
    
    event NameUpdated(address indexed user, string newName);
    event KeyUpdated(address indexed user, string newKey);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier profileExists() {
        require(profiles[msg.sender].exists, "Profile does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createProfile(string memory _name, string memory _key) public {
        require(!profiles[msg.sender].exists, "Profile already exists");
        
        profiles[msg.sender] = Profile({
            name: _name,
            key: _key,
            exists: true
        });
    }
    
    function updateName(string memory _newName) public profileExists {
        profiles[msg.sender].name = _newName;
        
        emit NameUpdated(msg.sender, _newName);
    }
    
    function updateKey(address _userAddress, string memory _newKey) public onlyOwner {
        require(profiles[_userAddress].exists, "Profile does not exist");
        
        profiles[_userAddress].key = _newKey;
        
        emit KeyUpdated(_userAddress, _newKey);
    }
    
    function getProfile(address _userAddress) public view returns (string memory name, string memory key) {
        require(profiles[_userAddress].exists, "Profile does not exist");
        
        Profile memory profile = profiles[_userAddress];
        return (profile.name, profile.key);
    }
} 
