pragma solidity ^0.5.0;

import './WineChainBase.sol';

/*
 *  Abstract contract for interfacing with the DateTime contract.
 */
contract DateTimeAPI {
    function isLeapYear(uint16 year) external pure returns (bool);
    function getYear(uint timestamp) external pure returns (uint16);
    function getMonth(uint timestamp) external pure returns (uint8);
    function getDay(uint timestamp) external pure returns (uint8);
    function getHour(uint timestamp) external pure returns (uint8);
    function getMinute(uint timestamp) external pure returns (uint8);
    function getSecond(uint timestamp) external pure returns (uint8);
    function getWeekday(uint timestamp) external pure returns (uint8);
    function toTimestamp(uint16 year, uint8 month, uint8 day) external pure returns (uint timestamp);
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) external pure returns (uint timestamp);
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) external pure returns (uint timestamp);
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) external pure returns (uint timestamp);
}

contract WineSupplyChain is WineChainBase {

    DateTimeAPI dateTimeAPI;

    string wineryName;
    uint yearFoundation;

    GrapeLot[] public grapeLots;
    WineLot[] wineLots;
    WineBarrel[] wineBarrels;
    WineBottle[] wineBottles;

    //WineLabel[] wineLabels;
    WinePacket[] winePackets;
    WinePallet[] winePallets;

    //mapping(address => WineLabel[]) wineLabelToProducer;

    OrderToProducer[] ordersToProducers;
    OrderToDistributor[] ordersToDistributors;

    uint grapeLotCount = 0;
    uint wineLotCount = 0;
    uint wineBarrelCount = 0;
    uint wineBottleCount = 0;
    uint winePacketCount = 0;
    uint winePalletCount = 0;
    uint ordersToProducersCount = 0;
    uint ordersToDistributorsCount = 0;

    uint numBottlesPerPacket = 6;
    uint numPacketsPerPallet = 12 * 4;  // 12 packets per layer, 4 layers

    mapping(uint => uint[]) public wineLotToBottleUpcRange;
    mapping(string => uint) amountInStockPerWineLabel;
    mapping(address => mapping(string => uint)) producerToWineLabelToPalletsAvailable;
    mapping(address => mapping(string => uint)) distributorToWineLabelToPacketsAvailable;
    mapping(address => mapping(string => uint)) producerToWineLabelToNextPalletIdAvailable;
    mapping(address => mapping(string => uint)) distributorToWineLabelToNextPacketIdAvailable;
    mapping(string => uint[]) wineLabelToWinePacketId;
    mapping(string => uint[]) wineLabelToWinePalletId;

    mapping(address => mapping(string => uint)) producerToWineLabelToPalletPrice;
    mapping(address => mapping(string => uint)) distributorToWineLabelToPacketPrice;

    mapping(address => uint) retailerToSku;

    mapping(string => CertificationTypeEnum) certificationPerWineLabel;
    //mapping(string => CertificationTypeEnum[]) certificationsPerWineLabel;
    uint certificationRequestCount = 0;
    CertificationRequest[] certificationRequests;

    // string[] public certificationTypes = ['IGT', 'IGP', 'DOC', 'DOCG', 'DOP', 'DEMETER', 'USDA ORGANIC'];
    // mapping(address => CertificationType[]) certifierToCertificationTypes;

    constructor(string memory _wineryName, uint _yearFoundation) public {
        wineryName = _wineryName;
        yearFoundation = _yearFoundation;
    }

    function setDateTimeAPI(address _address) public onlyOwner {
        dateTimeAPI = DateTimeAPI(_address);
    }

    modifier isGrapesHarvested(uint grapeLotNumber) {
        require(grapeLots[grapeLotNumber-1].state == StateEnum.GrapesHarvested);
        _;
    }

    modifier isGrapesProcessed(uint grapeLotNumber) {
        require(grapeLots[grapeLotNumber-1].state == StateEnum.GrapesProcessed);
        _;
    }

    modifier isWineProduced(uint wineLotNumber) {
        require(wineLots[wineLotNumber-1].state == StateEnum.WineProduced);
        _;
    }

    modifier isWineAged(uint wineLotNumber) {
        require(wineLots[wineLotNumber-1].state == StateEnum.WineAged);
        _;
    }

    modifier isWineBottledUp(uint wineLotNumber) {
        require(wineLots[wineLotNumber-1].state == StateEnum.WineBottledUp);
        _;
    }

    modifier isWineRested(uint wineLotNumber) {
        require(wineLots[wineLotNumber-1].state == StateEnum.WineRested);
        _;
    }

    modifier isWineReadyForSale(uint wineLotNumber) {
        require(wineLots[wineLotNumber-1].state == StateEnum.WineReadyForSale);
        _;
    }

    modifier onlyProducerOf(uint grapeLotNumber) {
        require(isProducer(msg.sender), "msg.sender must be an active wine producer");
        require(grapeLots[grapeLotNumber-1].producer == msg.sender, "msg.sender must be the producer of the grape lot");
        _;
    }

    modifier onlyWineProducerOf(uint wineLotNumber) {
        require(isProducer(msg.sender), "msg.sender must be an active wine producer");
        uint grapeLotNumber = wineLots[wineLotNumber-1].grapeLotNumber;
        require(grapeLots[grapeLotNumber-1].producer == msg.sender, "msg.sender must be the producer of the wine lot");
        _;
    }

    modifier onlyCertifierOf(uint certificationRequestId) {
        require(isCertifier(msg.sender), "msg.sender must be a certifier");
        require(certificationRequests[certificationRequestId-1].certifier == msg.sender);
        _;
    }

    modifier orderPlacedByDistributor(uint _orderId, address _distributor) {
        require(ordersToProducers[_orderId-1].distributor == _distributor);
        _;
    }

    modifier orderSubmittedToProducer(uint _orderId, address _producer) {
        require(ordersToProducers[_orderId-1].producer == _producer);
        _;
    }

    modifier orderPlacedByRetailer(uint _orderId, address _retailer) {
        require(ordersToDistributors[_orderId-1].retailer == _retailer);
        _;
    }

    modifier orderSubmittedToDistributor(uint _orderId, address _distributor) {
        require(ordersToDistributors[_orderId-1].distributor == _distributor);
        _;
    }

    modifier isWineReceivedByRetailer(uint orderId) {
        require(ordersToDistributors[orderId-1].retailer == msg.sender 
                && ordersToDistributors[orderId-1].status == OrderStatusEnum.Received);
        _;
    }

    modifier isWinePutForSale(uint _upc) {
        require(wineBottles[_upc-1].state == StateEnum.WinePutForSale);
        _;
    }

    modifier hasPaidEnough(uint _upc) {
        require(msg.value >= wineBottles[_upc-1].price);
        _;
    }

    function harvestGrapes(GrapeTypeEnum _grapeType, uint _amount, uint _harvestDate) public onlyProducer returns (uint grapeLotNumber) {
        grapeLotCount += 1;
        Producer storage producer = producers[msg.sender];
        emit GrapesHarvested(_grapeType, _amount);
        grapeLots.push(GrapeLot
            (
                grapeLotCount,
                msg.sender,
                dateTimeAPI.getYear(now),
                producer.location,
                producer.country,
                _grapeType,
                _harvestDate,
                0,
                _amount,
                0,
                StateEnum.GrapesHarvested
            )
        );
        return grapeLotCount;
    }

    function processGrapes(uint _grapeLotNumber, uint _mustVolume) public isGrapesHarvested(_grapeLotNumber) onlyProducerOf(_grapeLotNumber) {
        grapeLots[_grapeLotNumber-1].processingDate = now;
        grapeLots[_grapeLotNumber-1].mustVolume = _mustVolume;
        grapeLots[_grapeLotNumber-1].state = StateEnum.GrapesProcessed;
        emit GrapesProcessed(_grapeLotNumber, grapeLots[_grapeLotNumber-1].mustVolume);
    }

    function produceWine(uint _grapeLotNumber, uint _wineVolume, uint _fermentationTankId) public 
        isGrapesProcessed(_grapeLotNumber) 
        onlyProducerOf(_grapeLotNumber) 
        returns (uint wineLotNumber) 
    {
        wineLotCount += 1;
        wineLots.push(WineLot
        (
            wineLotCount,
            _grapeLotNumber,
            _fermentationTankId,
            now,
            _wineVolume,
            0,
            StateEnum.WineProduced
        ));
        emit WineProduced(wineLotCount, wineLots[wineLotCount-1].volume);
        return wineLotCount;
    }

    // function ageWine(uint _wineLotNumber, uint _barrelId, uint _numDaysOfAging) public isWineProduced(_wineLotNumber) onlyWineProducerOf(_wineLotNumber) {
    //     wineLots[_wineLotNumber-1].state = StateEnum.WineAged;
    //     //wineLots[_wineLotNumber-1].numDaysOfAging = _numDaysOfAging;
    //     //wineLots[_wineLotNumber-1].wineStartAgingDate = now;
    //     emit WineAged(_wineLotNumber, _numDaysOfAging);
    // }

    function bottleUpWine(uint _wineLotNumber, uint _bottleVolume, uint _numBottlesPerWineLot) public isWineAged(_wineLotNumber) onlyWineProducerOf(_wineLotNumber) {
        wineLots[_wineLotNumber-1].state = StateEnum.WineBottledUp;
        uint firstUpc = wineBottleCount + 1;
        for (uint i=0; i < _numBottlesPerWineLot; i++) {
            wineBottleCount += 1;
            wineBottles.push(WineBottle
            (
                wineBottleCount,
                _wineLotNumber,
                "",
                "",
                _bottleVolume,
                CertificationTypeEnum.None,
                0,
                0,
                StateEnum.WineBottledUp,
                now,0,0,0,0,0,0,0,0,0,0,0,0,
                address(0),address(0),address(0)
            ));
        }
        uint lastUpc = wineBottleCount;
        wineLotToBottleUpcRange[_wineLotNumber].push(firstUpc);
        wineLotToBottleUpcRange[_wineLotNumber].push(lastUpc);
        wineLots[_wineLotNumber-1].numBottles = lastUpc - firstUpc + 1;
        emit WineBottledUp(_wineLotNumber, _numBottlesPerWineLot, firstUpc, lastUpc);
    }

    function restWineBottles(uint _wineLotNumber, uint _numDaysOfRest) public isWineBottledUp(_wineLotNumber) onlyWineProducerOf(_wineLotNumber) {
        wineLots[_wineLotNumber-1].state = StateEnum.WineRested;
        uint[] memory upcRange = wineLotToBottleUpcRange[_wineLotNumber];
        uint firstUpc = upcRange[0];
        uint lastUpc = upcRange[1];
        uint numBottles = lastUpc - firstUpc + 1;
        for(uint upc=firstUpc; upc <= lastUpc; upc++) {
            wineBottles[upc-1].numDaysOfRest = _numDaysOfRest;
            wineBottles[upc-1].wineRestedDate = now;
            wineBottles[upc-1].state = StateEnum.WineRested;
        }
        emit WineRested(_wineLotNumber, numBottles, firstUpc, lastUpc);
    }

    function addLabels(uint _wineLotNumber, string memory _wineLabel, string memory _description) public isWineRested(_wineLotNumber) onlyWineProducerOf(_wineLotNumber) {
        wineLots[_wineLotNumber-1].state = StateEnum.WineLabeled;
        uint[] memory upcRange = wineLotToBottleUpcRange[_wineLotNumber];
        uint firstUpc = upcRange[0];
        uint lastUpc = upcRange[1];
        uint numBottles = lastUpc - firstUpc + 1;
        for(uint upc=firstUpc; upc <= lastUpc; upc++) {
            wineBottles[upc-1].wineLabel = _wineLabel;
            wineBottles[upc-1].description = _description;
            wineBottles[upc-1].certification = certificationPerWineLabel[_wineLabel];
            wineBottles[upc-1].wineLabeledDate = now;
            wineBottles[upc-1].state = StateEnum.WineLabeled;
        }
        emit WineLabeled(_wineLotNumber, numBottles, firstUpc, lastUpc);
    }

    function packWine(uint _wineLotNumber, uint _firstUpc, uint _lastUpc) public onlyProducerOf(_wineLotNumber) {
        uint countBottlesForPacket = 0;
        uint countPacketsForPallet = 0;
        uint firstUpcCurrentPacket = _firstUpc;
        uint firstPacketIdCurrentPallet = winePacketCount + 1;
        string memory wineLabel = wineBottles[_firstUpc-1].wineLabel;
        for(uint upc=_firstUpc; upc <= _lastUpc; upc++) {
            wineBottles[upc-1].wineReadyDate = now;
            wineBottles[upc-1].state = StateEnum.WineReadyForSale;
            countBottlesForPacket += 1;
            if (firstUpcCurrentPacket == 0) firstUpcCurrentPacket = upc;
            if (countBottlesForPacket == numBottlesPerPacket) {
                countBottlesForPacket = 0;
                countPacketsForPallet += 1;
                winePacketCount += 1;
                winePackets.push(WinePacket(
                    winePacketCount,
                    wineLabel,
                    firstUpcCurrentPacket,
                    upc,
                    address(0), address(0)
                ));
                firstUpcCurrentPacket = 0;
                if (countPacketsForPallet == numPacketsPerPallet) {
                    countPacketsForPallet = 0;
                    winePalletCount += 1;
                    winePallets.push(WinePallet(
                        winePalletCount,
                        wineLabel,
                        numPacketsPerPallet,
                        firstPacketIdCurrentPallet,
                        winePacketCount,
                        address(0)
                    ));
                }
            }           
        }
        uint numBottles = _lastUpc - _firstUpc + 1;
        emit WineReadyForSale(_wineLotNumber, numBottles, _firstUpc, _lastUpc);
    }

    function applyForCertification(address _certifier, string memory _wineLabel, CertificationTypeEnum _certificationType) public onlyProducer payable {
        require(isCertifier(_certifier), "The address must belong to an active certifier");
        certificationRequestCount += 1;
        certificationRequests.push(CertificationRequest
        (
            certificationRequestCount,
            msg.sender,
            _certifier,
            _wineLabel,
            _certificationType,
            CertificationRequestStatusEnum.Pending
        ));
        emit ProducerAppliedForCertification(certificationRequestCount, msg.sender, _certifier, _wineLabel, _certificationType);
    }

    function certifyProducer(uint _certificationRequestId, bool accepted) public onlyCertifierOf(_certificationRequestId) {
        string memory wineLabel = certificationRequests[_certificationRequestId-1].wineLabel;
        CertificationTypeEnum certificationType = certificationRequests[_certificationRequestId-1].certificationType;
        certificationRequests[_certificationRequestId-1].status = 
            (accepted ? CertificationRequestStatusEnum.Accepted : CertificationRequestStatusEnum.Denied);
        certificationPerWineLabel[wineLabel] = (accepted ? certificationType : CertificationTypeEnum.None);
        emit ProducerCertified(_certificationRequestId, accepted);
    }

    function placeOrderToProducer(address _producer, string memory _wineLabel, uint _numPallets) public onlyDistributor payable {
        require(isProducer(_producer), "The adress must belong to an active producer");
        require(producerToWineLabelToPalletsAvailable[_producer][_wineLabel] >= _numPallets);
        uint palletPrice = producerToWineLabelToPalletPrice[_producer][_wineLabel];
        require(msg.value >= palletPrice * _numPallets);
        uint change = msg.value - (palletPrice * _numPallets);
        ordersToProducersCount += 1;
        ordersToProducers.push(OrderToProducer(
            ordersToProducersCount,
            now,
            _producer,
            msg.sender,
            _wineLabel,
            _numPallets,
            0,0,
            OrderStatusEnum.Placed
        ));
        msg.sender.transfer(change);
        emit WineSold(ordersToProducersCount, _wineLabel, _numPallets);
    }

    function shipOrderToDistributor(uint _orderId, address _distributor) public orderPlacedByDistributor(_orderId, _distributor) orderSubmittedToProducer(_orderId, msg.sender) {
        uint numPallets = ordersToProducers[_orderId-1].numPallets;
        string memory wineLabel = ordersToProducers[_orderId-1].wineLabel;
        uint firstPalletId = producerToWineLabelToNextPalletIdAvailable[msg.sender][wineLabel];
        ordersToProducers[_orderId-1].firstPalletId = firstPalletId;
        uint palletsFound=0;
        uint i=0;
        while (palletsFound <= numPallets) {
            WinePallet memory nextPalletAvailable = winePallets[firstPalletId-1 + i];
            if (keccak256(abi.encode(nextPalletAvailable.wineLabel)) == keccak256(abi.encode(wineLabel))) {
                if (palletsFound < numPallets) {
                    palletsFound += 1;
                    nextPalletAvailable.distributor = _distributor;
                    for (uint packetId = nextPalletAvailable.firstPacketId; packetId <= nextPalletAvailable.lastPacketId; packetId++) {
                        winePackets[packetId-1].distributor = _distributor;
                        for (uint upc=winePackets[packetId-1].firstUpc; upc <= winePackets[packetId-1].lastUpc; upc++) {
                            wineBottles[upc-1].distributor = _distributor;
                            wineBottles[upc-1].state = StateEnum.WineShippedToDistributor;
                        }
                    }
                    ordersToProducers[_orderId-1].lastPalletId = firstPalletId + i;
                } else {
                    producerToWineLabelToNextPalletIdAvailable[msg.sender][wineLabel] = firstPalletId + i;
                }
            }
            i += 1;
        }
        ordersToProducers[_orderId-1].status = OrderStatusEnum.Shipped;
        emit WineShippedToDistributor(_orderId, wineLabel, numPallets, _distributor);
    }

    function wineReceivedByDistributor(uint _orderId) public onlyDistributor orderPlacedByDistributor(_orderId, msg.sender) {
        uint numPallets = ordersToProducers[_orderId-1].numPallets;
        string memory wineLabel = ordersToProducers[_orderId-1].wineLabel;
        uint firstPalletId = ordersToProducers[_orderId-1].firstPalletId;
        uint palletsFound=0; 
        uint i=0;
        while (palletsFound <= numPallets) {
            WinePallet memory nextPalletAvailable = winePallets[firstPalletId-1 + i];
            if (keccak256(abi.encode(nextPalletAvailable.wineLabel)) == keccak256(abi.encode(wineLabel))) {
                if (palletsFound < numPallets) {
                    palletsFound += 1;
                    for (uint packetId = nextPalletAvailable.firstPacketId; packetId <= nextPalletAvailable.lastPacketId; packetId++) {
                        for (uint upc=winePackets[packetId-1].firstUpc; upc <= winePackets[packetId-1].lastUpc; upc++) {
                            wineBottles[upc-1].state = StateEnum.WineReceivedByDistributor;
                        }
                    }
                } 
            }
            i += 1;
        }
        ordersToProducers[_orderId-1].status = OrderStatusEnum.Received;
        emit WineReceivedByDistributor(_orderId);
    }

    function placeOrderToDistributor(address _distributor, string memory _wineLabel, uint _numPackets) public onlyRetailer payable {
        require(isDistributor(_distributor), "The adress must belong to an active distributor");
        require(distributorToWineLabelToPacketsAvailable[_distributor][_wineLabel] >= _numPackets);
        uint packetPrice = distributorToWineLabelToPacketPrice[_distributor][_wineLabel];
        require(msg.value >= packetPrice * _numPackets);
        uint change = msg.value - (packetPrice * _numPackets);
        ordersToDistributorsCount += 1;
        ordersToDistributors.push(OrderToDistributor(
            ordersToDistributorsCount,
            now,
            _distributor,
            msg.sender,
            _wineLabel,
            _numPackets,
            0,0,
            OrderStatusEnum.Placed
        ));
        msg.sender.transfer(change);
        emit WineSold(ordersToDistributorsCount, _wineLabel, _numPackets);
    }

    function shipWineToRetailer(uint _orderId, address _retailer) public orderSubmittedToDistributor(_orderId, msg.sender) orderPlacedByRetailer(_orderId, _retailer) {
        uint numPackets = ordersToDistributors[_orderId-1].numPackets;
        string memory wineLabel = ordersToDistributors[_orderId-1].wineLabel;
        uint firstPacketId = distributorToWineLabelToNextPacketIdAvailable[msg.sender][wineLabel];
        ordersToDistributors[_orderId-1].firstPacketId = firstPacketId;
        uint packetsFound=0;
        uint i=0;
        while (packetsFound <= numPackets) {
            WinePacket memory nextPacketAvailable = winePackets[firstPacketId-1 + i];
            if (keccak256(abi.encode(nextPacketAvailable.wineLabel)) == keccak256(abi.encode(wineLabel))) {
                if (packetsFound < numPackets) {
                    packetsFound += 1;
                    nextPacketAvailable.retailer = _retailer;
                    for (uint upc=nextPacketAvailable.firstUpc; upc <= nextPacketAvailable.lastUpc; upc++) {
                        wineBottles[upc-1].retailer = _retailer;
                        wineBottles[upc-1].state = StateEnum.WineShippedToRetailer;
                    }
                    ordersToDistributors[_orderId-1].lastPacketId = firstPacketId+i;
                } else {
                    distributorToWineLabelToNextPacketIdAvailable[msg.sender][wineLabel] = firstPacketId + i;
                }
            }
            i += 1;
        }
        ordersToDistributors[_orderId-1].status = OrderStatusEnum.Shipped;
        emit WineShippedToRetailer(_orderId, wineLabel, numPackets, _retailer);
    }

    function wineReceivedByRetailer(uint _orderId) public onlyRetailer orderPlacedByRetailer(_orderId, msg.sender) {
        uint numPackets = ordersToDistributors[_orderId-1].numPackets;
        string memory wineLabel = ordersToDistributors[_orderId-1].wineLabel;
        uint firstPacketId = ordersToDistributors[_orderId-1].firstPacketId;
        uint packetsFound=0; 
        uint i=0;
        while (packetsFound <= numPackets) {
            WinePacket memory nextPacketAvailable = winePackets[firstPacketId-1 + i];
            if (keccak256(abi.encode(nextPacketAvailable.wineLabel)) == keccak256(abi.encode(wineLabel))) {
                if (packetsFound < numPackets) {
                    packetsFound += 1;
                    for (uint upc = nextPacketAvailable.firstUpc; upc <= nextPacketAvailable.lastUpc; upc++) {
                        wineBottles[upc-1].state = StateEnum.WineReceivedByRetailer;
                    }
                } 
            }
            i += 1;
        }
        ordersToDistributors[_orderId-1].status = OrderStatusEnum.Received;
        emit WineReceivedByRetailer(_orderId);
    }

    function putWineForSale(uint _orderId, string memory _wineLabel, uint _price) public onlyRetailer isWineReceivedByRetailer(_orderId) {
        uint firstPacketId = ordersToDistributors[_orderId-1].firstPacketId;
        uint lastPacketId = ordersToDistributors[_orderId-1].lastPacketId;
        for (uint packetId=firstPacketId; packetId <= lastPacketId; packetId++) {
            WinePacket memory packet = winePackets[packetId-1];
            if (keccak256(abi.encode(packet.wineLabel)) == keccak256(abi.encode(_wineLabel))) {
                for (uint upc = packet.firstUpc; upc <= packet.lastUpc; upc++) {
                    uint nextSku = retailerToSku[msg.sender] + 1;
                    wineBottles[upc-1].state = StateEnum.WinePutForSale;
                    wineBottles[upc-1].price = _price;
                    wineBottles[upc-1].sku = nextSku;
                } 
            }
        }
        emit WinePutForSale(_orderId, _wineLabel, msg.sender, _price);
    }

    function buyWine(uint _upc) public onlyConsumer isWinePutForSale(_upc) hasPaidEnough(_upc) payable {
        uint change = msg.value - wineBottles[_upc-1].price;
        wineBottles[_upc-1].wineBoughtDate = now;
        msg.sender.transfer(change);
        emit WineBought(_upc, wineBottles[_upc-1].retailer, wineBottles[_upc-1].sku, msg.sender);
    }
}