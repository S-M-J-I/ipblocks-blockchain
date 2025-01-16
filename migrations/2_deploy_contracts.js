const HelloWorldContract = artifacts.require("HelloWorldContract")

module.exports = async function (deployer) {
    await deployer.deploy(HelloWorldContract)
}