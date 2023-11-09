# 🌱 Carbon Layer 

This project feeds carbon intensity data from the [National Grid](https://www.nationalgrid.com/uk) official [Carbon Intesity API](https://api.carbonintensity.org.uk/) to a carbon intensity consumer contract which exposes its state to be used as part of a composed stack enabling other contracts to limit compute to times of low carbon generation, in other words, services can run in eco mode.



## Chainlink Node

* Configure & launch a node according to the [docs](https://docs.chain.link/chainlink-nodes/v1/running-a-chainlink-node)

* Fund the node address (http://localhost:6688/keys)

* Add a new job according to the [docs](https://docs.chain.link/chainlink-nodes/v1/fulfilling-requests#add-a-job-to-the-node)  

* **NOTE:** dont forget to set up a view role [docs](https://docs.chain.link/chainlink-nodes/v1/roles-and-access)

## Chainlink Data Feed

* Deploy an operator contract according to the [docs](https://docs.chain.link/chainlink-nodes/v1/fulfilling-requests#setup-your-operator-contract)

* Deploy CarbonLayer.sol, referencing the testConsumer in the [docs](https://docs.chain.link/chainlink-nodes/v1/fulfilling-requests#create-a-request-to-your-node)

* **NOTE:** consumer should have an onlyOracle modifier on fulfillOracleResponse

## Chainlink Automation

* Deploy and fund a new upkeep on [Chainlink Automation](https://automation.chain.link/) 

* **NOTE:** update the state at a defined interval (frequency 30min)

## Chainlink CCIP

* **TODO:** look into replicating state across chains. What effect will the CCIP delay have on the service.

* **NOTE:** dont forget the deployer nonce needs to be the same one all chains

## Sample Integration
**TODO:** create a uniswap v4 hook to demonstrate disabling a pool during times of peek carbon intensity

## Hardhat

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
