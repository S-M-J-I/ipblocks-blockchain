const web3 = require('web3')
const IPBlockchainPro = artifacts.require('IPBlockchainProContract')
const BlockchainPerformanceAnalyzer = require('./perf')
const ConcurrentBlockchainPerformanceAnalyzer = require('./load')

contract('IPBlockchainPro', (accounts) => {
    let transactionTimeContract
    let account

    before(async () => {
        transactionTimeContract = await IPBlockchainPro.deployed()
        account = "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1"
    })

    async function measureTransactionPerformance(iterations = 10) {
        const performanceResults = []

        for (let i = 0; i < iterations; i++) {
            const startTime = Date.now()

            const transaction = await transactionTimeContract.publishIP(
                `${Date.now()}-${Math.floor(performance.now())}-${Math.floor(Math.random() * 100000)}`,
                'Title',
                0,
                Date.now(),
                Date.now(),
                Date.now(),
                [account],
                { from: account }
            )

            const endTime = Date.now()
            const localProcessingTime = endTime - startTime

            const transactionHash = transaction.tx

            const receipt = transaction['receipt']
            const gasUsed = receipt['gasUsed']

            performanceResults.push({
                iteration: i,
                localProcessingTime,
                gasUsed,
                transactionHash
            })
        }


        const performanceAnalyzer = new BlockchainPerformanceAnalyzer(web3, transactionTimeContract)
        const results = await performanceAnalyzer.runPerformanceTest(
            () => transactionTimeContract.publishIP(
                `${Date.now()}-${Math.floor(performance.now())}-${Math.floor(Math.random() * 100000)}`,
                'Title',
                0,
                Date.now(),
                Date.now(),
                Date.now(),
                [account],
                {
                    from: account,
                }
            ),
            10
        )
        const report = performanceAnalyzer.generatePerformanceReport(results)

        return performanceResults
    }

    async function runMultiClientTests() {
        const config = {
            numClients: 5,
            iterationsPerClient: 10,
            concurrencyMode: 'parallel'
        }

        // Create multiple web3 instances
        const web3Instances = []
        for (let i = 0; i < config.numClients; i++) {
            web3Instances.push(new web3.Web3())
        }

        const contractInstance = await IPBlockchainPro.deployed()

        // console.log("Contract instances")
        // console.log(contractInstances)

        const concurrentAnalyzer = new ConcurrentBlockchainPerformanceAnalyzer(
            web3Instances,
            contractInstance
        )

        // Define your test function
        const testFunction = (txOptions = {}) => {
            return contractInstance.publishIP(
                `${Date.now()}-${Math.floor(performance.now())}-${Math.floor(Math.random() * 100000)}`,
                'Title',
                0,
                Date.now(),
                Date.now(),
                Date.now(),
                [account],
                {
                    from: account,
                    ...txOptions
                }
            )
        }

        const results = await concurrentAnalyzer.runConcurrentTests(
            testFunction, config
        )

        const report = concurrentAnalyzer.generatePerformanceReport(results)

        return results
    }

    // it('Should measure transaction processing performance for one client', async () => {
    //     const results = await measureTransactionPerformance()

    //     console.table(results)

    //     // Calculate statistics
    //     const avgLocalProcessingTime =
    //         results.reduce((sum, result) => sum + result.localProcessingTime, 0) / results.length

    //     console.log(`Average Local Processing Time: ${avgLocalProcessingTime.toFixed(2)} ms`)
    // })

    it('Should measure transaction processing performance for multiple clients', async () => {
        const results = await runMultiClientTests()

        console.log("Concurrent results")
        console.log(results)

        const avgLocalProcessingTime =
            results['overallAvgProcessingTime']

        console.log(`Average Local Processing Time for Clients: ${avgLocalProcessingTime.toFixed(2)} ms`)
    })
})
