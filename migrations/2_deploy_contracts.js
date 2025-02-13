const IPBlockchainProContract = artifacts.require("IPBlockchainProContract")

module.exports = async function (deployer) {
    await deployer.deploy(IPBlockchainProContract)
}