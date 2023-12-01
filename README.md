# 🌱 Carbon Layer 

This project feeds carbon intensity data from the [National Grid](https://www.nationalgrid.com/uk) official [Carbon Intesity API](https://api.carbonintensity.org.uk/) to a carbon intensity consumer contract which exposes its state to be used as part of a composed stack enabling other contracts to limit compute to times of low carbon generation, in other words, services can run in eco mode.

## Sepolia Addresses
| Contract        | Address                                    |
|-----------------|------------------------------------------- |
| Operator        | 0xd3e4028bC6b50091112641b565bE049f535D6299 |
| Carbon Layer    | 0x1749456Bd2Fe5D37AFBD73Bb59995e89F97aDce4 |
| Carbon Assert   | 0xA3A6C7865706E5E9cc594c3FC5ef534C50316Ab5 |
| Carbon Query    | 0x82c2F109A7979909Da4894f5EeF8085Ed90686dd |
| Upkeep          | 0xFe7B5DB07b96Dff57A200cB8a34aAbc654C6aD66 |
| Oracle Node     | 0x44A1542d44df86f7AC5Fed208cc77D39E6F18eC0 |
| Carbon Compute  | 0xcc60eD9BF0Ab6F4234e57F18AbCaAaACcA799627 |
| Carbon Stats    | 0x1D2C03688D0777F4A1De327c7fA76d454B4e8a62 |
| ~~Demo01~~      |~~0x9C30040ECAD7f2E39073fa7f40F8F91528FE5c95~~|


## Chainlink Node

* Configure & launch a node either:
  * according to the [docs](https://docs.chain.link/chainlink-nodes/v1/running-a-chainlink-node), or
  * following the [readme](./chainlink-node/README.md) for a docker compose setup. (Reccomended)   

* Fund your node [address](http://localhost:6688/keys) with ETH


* Add the intesity.toml and mix.toml from [jobs](./chainlink-node/jobs/) 

* **NOTE:** dont forget to set up a view role [docs](https://docs.chain.link/chainlink-nodes/v1/roles-and-access)

## Chainlink Data Feed

* Deploy an instance of the [operator](./contracts/Operator.sol) and save the address.

* Set the node [address](http://localhost:6688/keys) as an authorised sender on the **Operator**

* Deploy an instance of [CarbonLayer](./contracts/CarbonLayer.sol)

* Fund **CarbonLayer** with Link. Each update costs 0.2 Link 

* **NOTE:** TODO: investigate access control modifier on fulfillOracleResponse functions ???

## Chainlink Automation

* Deploy and fund a new upkeep on [Chainlink Automation](https://automation.chain.link/) 

* Create a time interval based upkeep that points to **Carbon Layer**. The upkeep should call the `update` function with the **Operator** address and the job id's for `Get UK Carbon Intensity Index` & `Get UK Carbon Intensity Mix`. 

* Copy the Upkeep address from the [Chainlink Automation](https://automation.chain.link/) dashboard and call `setAutomation` on **Carbon Layer** to authenticate the upkeep.


* **NOTE:** gas limit should be >= 250,000
* **NOTE:** api update interval = 30min 

## Chainlink CCIP

* **TODO:** look into replicating state across chains. What effect will the CCIP delay have on the service.

* **NOTE:** dont forget the deployer nonce needs to be the same one all chains

## Sample Integrations

### AWS Lambda 
A sample workflow to use a contract as a payment processor for an offchain compute task. In this sample The payment processor exposes a function `doWork` which charges a fee to access a compute function on AWS. 

The fee varies based on the percentage of carbon neutral energy being used to power the grid, for instance if more than 50% of the energy is sourced from wind, solar, hydro, etc, a reduced fee is charged.

The payment contract impliments CarbonLayer to source the fuel generation mix and then uses ChainLink Functions to make a call to AWS where the compute is carried out. Finally the result is returned to the  payment contract.

#### Getting Started
* Deploy a [lambda](examples/carbonCompute/simpleLambda.js) containing business logic for the compute job.
* Configure [CarbonCompute](examples/carbonCompute/CarbonCompute.sol) to reference the lambda and parse the response.
* Deploy the [CarbonCompute](examples/carbonCompute/CarbonCompute.sol) contract
* Follow the [Managing CL Functions Subscriptions guide](https://docs.chain.link/chainlink-functions/resources/subscriptions#create-a-subscriptio) and make a note of your subscription id. 
* Add the address as a comsumer of your [Chainlink Functions](https://functions.chain.link/) subscription.
* Configure the CarbonLayer renewable energy threshold for your use case using setTreshold, eg. `setTreshold(500)` sets a requirement for a 50% renewable energy source.
* Configure the standard and reduced fees using setFees, eg. `setFees(2000000000000000, 1000000000000000)` sets a fee of 0.002 ETH and a reduced fee of 0.001 ETH.

### Uniswap Hook
**TODO:** create a uniswap v4 hook to demonstrate disabling a pool during times of peek carbon intensity

## Hardhat

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
