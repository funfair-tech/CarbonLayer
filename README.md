# 🌱 Carbon Layer 

This project feeds carbon intensity data from the [National Grid](https://www.nationalgrid.com/uk) official [Carbon Intesity API](https://api.carbonintensity.org.uk/) to a carbon intensity consumer contract which exposes its state to be used as part of a composed stack enabling other contracts to limit compute to times of low carbon generation, in other words, services can run in eco mode.

## Sepolia Addresses
| Contract        | Address                                    |
|-----------------|------------------------------------------- |
| Operator        | 0xd3e4028bC6b50091112641b565bE049f535D6299 |
| Carbon Layer    | 0x6D8B45aDBa8FA809d04F0ae84793476e81F97d42 |
| Carbon Assert   | 0x9B52F1505A7f9cb3dE674C8CE1C77d480AAc1209 |
| Carbon Query    | 0x4A69f59AfD22AC7935445b375Fa3D13e70775Cdb |
| Upkeep          | 0xFe7B5DB07b96Dff57A200cB8a34aAbc654C6aD66 |
| Oracle Node     | 0x44A1542d44df86f7AC5Fed208cc77D39E6F18eC0 |
| Demo01          | 0xB09D6e6C90c843d6e350237f494dad87951dB529 |


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
