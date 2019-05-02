var WineChainAccessControl = artifacts.require("./WineChainAccessControl.sol");
var WineSupplyChain = artifacts.require("./WineSupplyChain.sol");

module.exports = function(deployer) {
    deployer.deploy(WineChainAccessControl);
    deployer.deploy(WineSupplyChain, 'Vinicola Oliveros', 2020);
};

