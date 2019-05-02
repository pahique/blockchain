pragma solidity ^0.5.0;

import './Ownable.sol';

contract WineChainAccessControl is Ownable {

    mapping(address => Producer) public producers;
    mapping(address => Certifier) public certifiers;
    mapping(address => Distributor) public distributors;
    mapping(address => Retailer) public retailers;
    mapping(address => Consumer) consumers;

    struct Producer {
        address producerAddress;
        string name;
        string location;
        string country;
        uint16 yearFoundation;
        bool isActive;
    }

    struct Distributor {
        address distributorAddress;
        string name;
        string location;
        string country;
        bool isActive;
    }

    struct Certifier {
        address certifierAddress;
        string name;
        bool isActive;
    }

    struct Retailer {
        address retailerAddress;
        string name;
        bool isActive;
    }

    struct Consumer {
        address consumerAddress;
        string name;
    }

    function isProducer(address _address) public view returns (bool) {
        return(producers[_address].producerAddress != address(0) && producers[_address].isActive);
    }

    function isCertifier(address _address) public view returns (bool) {
        return(certifiers[_address].certifierAddress != address(0) && certifiers[_address].isActive);
    }

    function isDistributor(address _address) public view returns (bool) {
        return(distributors[_address].distributorAddress != address(0) && distributors[_address].isActive);
    }

    function isRetailer(address _address) public view returns (bool) {
        return(retailers[_address].retailerAddress != address(0) && retailers[_address].isActive);
    }

    function isConsumer(address _address) public view returns (bool) {
        return(consumers[_address].consumerAddress != address(0));
    }

    modifier onlyProducer() {
        require(isProducer(msg.sender), "msg.sender is not an active wine producer");
        _;
    }

    modifier onlyCertifier() {
        require(isCertifier(msg.sender), "msg.sender is not an active certifier");
        _;
    }

    modifier onlyDistributor() {
        require(isDistributor(msg.sender), "msg.sender is not an active distributor");
        _;
    }

    modifier onlyRetailer() {
        require(isRetailer(msg.sender), "msg.sender is not an active retailer");
        _;
    }

    modifier onlyConsumer() {
        require(isConsumer(msg.sender), "msg.sender is not a consumer");
        _;
    }

    function addProducer(
        address _producerAddress, 
        string memory _name,
        string memory _location,
        string memory _country,
        uint16 _yearFoundation) 
        public onlyOwner 
    {
        producers[_producerAddress] = Producer(_producerAddress, _name, _location, _country, _yearFoundation, true);
    }

    function removeProducer(address _producerAddress) public onlyOwner {
        producers[_producerAddress].isActive = false;
    }

    function addCertifier(address _certifierAddress, string memory _name) public onlyOwner {
        certifiers[_certifierAddress] = Certifier(_certifierAddress, _name, true);
    }

    function removeCertifier(address _certifierAddress) public onlyOwner {
        certifiers[_certifierAddress].isActive = false;
    }

    function addDistributor(
        address _distributorAddress, 
        string memory _name, 
        string memory _location, 
        string memory _country) 
        public onlyOwner 
    {
        distributors[_distributorAddress] = Distributor(_distributorAddress, _name, _location, _country, true);
    }

    function removeDistributor(address _distributorAddress) public onlyOwner {
        distributors[_distributorAddress].isActive = false;
    }

    function addRetailer(address _retailerAddress, string memory _name) public onlyOwner {
        retailers[_retailerAddress] = Retailer(_retailerAddress, _name, true);
    }

    function removeRetailer(address _retailerAddress) public onlyOwner {
        retailers[_retailerAddress].isActive = false;
    }

}