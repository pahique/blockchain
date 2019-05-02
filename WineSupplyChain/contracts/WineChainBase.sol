pragma solidity ^0.5.0;

import './WineChainAccessControl.sol';

contract WineChainBase is WineChainAccessControl {
    
    enum StateEnum {
        GrapesHarvested,
        GrapesProcessed,
        WineProduced,
        WineAged,
        WineBottledUp,
        WineRested,
        WineLabeled,
        WineReadyForSale,
        WineSold,
        WinePacked,
        WineShippedToDistributor,
        WineReceivedByDistributor,
        WineShippedToRetailer,
        WineReceivedByRetailer,
        WinePutForSale,
        WineBought
    } 

    enum GrapeTypeEnum {
        CabernetSauvignon,
        Merlot,
        Carmenere,
        PinotNoir,
        Malbec,
        Shiraz,
        SauvignonBlanc,
        Chardonnay,
        Moscatel,
        Bonarda,
        Tannat
    }

    // struct CertificationType {
    //     uint16 id;
    //     string name;
    //     uint costInWei;
    // }

    enum CertificationTypeEnum {
        None,
        IGT,
        IGP,
        DOC,
        DOCG,
        DOP,
        ORGANIC,
        DEMETER
    }

    struct GrapeLot {
        uint number;
        address producer;
        uint16 year;
        string location;
        string country;
        GrapeTypeEnum grapeType;
        uint harvestDate;
        uint processingDate;
        uint amount;
        uint mustVolume;
        StateEnum state;
    }

    struct WineLot {
        uint number;
        uint grapeLotNumber;
        uint fermentationTankId;
        uint fermentationStartDate;
        uint volume;
        uint numBottles;
        StateEnum state;
    }

    struct WineBarrel {
        uint number;
        uint wineLotNumber;
        uint barrelId;
        uint volume;
        uint wineAgingStartDate;
        uint numBottles;
    }

    struct WineBottle {
        uint upc;
        uint wineLotNumber;
        string wineLabel;
        string description;
        uint volume;
        CertificationTypeEnum certification;
        uint sku;
        uint price;
        StateEnum state;
        uint bottlingDate;
        uint numDaysOfRest;
        uint wineRestedDate;
        uint wineLabeledDate;
        uint wineReadyDate;
        uint wineSoldDate;
        uint winePackedDate;
        uint shippedToDistributorDate;
        uint receivedByDistributorDate;
        uint shippedToRetailerDate;
        uint receivedByRetailerDate;
        uint winePutForSaleDate;
        uint wineBoughtDate;

        address certifier;
        address distributor;
        address retailer;
    }

    // struct WineLabel {
    //     address producer;
    //     string label;
    //     string description;
    // }

    struct WinePacket {
        uint packetId;
        string wineLabel;
        uint firstUpc;
        uint lastUpc;
        address distributor;
        address retailer;
    }

    struct WinePallet {
        uint palletId;
        string wineLabel;
        uint numPackets;
        uint firstPacketId;
        uint lastPacketId;
        address distributor;
    }

    struct CertificationRequest {
        uint requestId;
        address producer;
        address certifier;
        string wineLabel;
        CertificationTypeEnum certificationType;
        CertificationRequestStatusEnum status;
    }

    enum CertificationRequestStatusEnum {
        Pending,
        Accepted,
        Denied
    }

    struct OrderToProducer {
        uint id;
        uint orderDate;
        address producer;
        address distributor;
        string wineLabel;
        uint numPallets;
        uint firstPalletId;
        uint lastPalletId;
        OrderStatusEnum status;
    }

    enum OrderStatusEnum {
        Placed,
        Shipped,
        Received
    }

    struct OrderToDistributor {
        uint id;
        uint orderDate;
        address distributor;
        address retailer;
        string wineLabel;
        uint numPackets;
        uint firstPacketId;
        uint lastPacketId;
        OrderStatusEnum status;
    }

    event GrapesHarvested(GrapeTypeEnum grapeType, uint amount);
    event GrapesProcessed(uint grapeLotNumber, uint mustVolume);
    event WineProduced(uint wineLotNumber, uint wineVolume);
    event WineAged(uint wineLotNumber, uint wineVolume);
    event WineBottledUp(uint wineLotNumber, uint numBottles, uint firstUpc, uint lastUpc);
    event WineRested(uint wineLotNumber, uint numBottles, uint firstUpc, uint lastUpc);
    event WineLabeled(uint wineLotNumber, uint numBottles, uint firstUpc, uint lastUpc);
    event WineReadyForSale(uint wineLotNumber, uint numBottles, uint firstUpc, uint lastUpc);
    event WineSold(uint orderId, string wineLabel, uint numPallets);
    event WineShippedToDistributor(uint orderId, string wineLabel, uint numPallets, address distributor);
    event WineReceivedByDistributor(uint orderId);
    event WineSoldToRetailer(uint orderId, string wineLabel, uint numPackets);
    event WineShippedToRetailer(uint orderId, string wineLabel, uint numPackets, address retailer);
    event WineReceivedByRetailer(uint orderId);
    event WinePutForSale(uint orderId, string wineLabel, address retailer, uint price);
    event WineBought(uint upc, address retailer, uint sku, address consumer);

    event ProducerAppliedForCertification(uint requestId, address producer, address certifier, string wineLabel, CertificationTypeEnum certification);
    event ProducerCertified(uint requestId, bool accepted);
}