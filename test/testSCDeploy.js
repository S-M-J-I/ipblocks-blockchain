const HelloWorldContract = artifacts.require("HelloWorldContract")

contract("HelloWorldContract", (accounts) => {
    it("should set and print hello world correctly", async () => {
        const instance = await HelloWorldContract.deployed()
        await instance.setWord("Hello World hehehe")
        const value = await instance.getWord()
        assert.equal(value, "Hello World hehehe", "The value was not set correctly.")
    })
})