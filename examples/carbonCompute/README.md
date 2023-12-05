## Carbon Compute 
A sample workflow to use a contract as a payment processor for an off chain compute task. In this sample The payment processor exposes a function `doWork` which charges a fee to access a compute function on AWS. 

The fee varies based on the percentage of carbon-neutral energy being used to power the grid, for instance if more than 50% of the energy is sourced from wind, solar, hydro, etc, a reduced fee is charged.

The payment contract implements CarbonLayer to source the fuel generation mix and then uses ChainLink Functions to make a call to AWS where the compute is carried out. Finally, the result is returned to the  payment contract.

## Sepolia Addresses
| Contract        | Address                                    |
|-----------------|------------------------------------------- |
| Carbon Compute  | 0xcc60eD9BF0Ab6F4234e57F18AbCaAaACcA799627 |
| Carbon Stats    | 0x1D2C03688D0777F4A1De327c7fA76d454B4e8a62 |

#### Getting Started
* Deploy a [lambda](examples/carbonCompute/simpleLambda.js) containing business logic for the compute job.
* Configure [CarbonCompute](examples/carbonCompute/CarbonCompute.sol) to reference the lambda and parse the response.
* Deploy the [CarbonCompute](examples/carbonCompute/CarbonCompute.sol) contract
* Follow the [Managing CL Functions Subscriptions guide](https://docs.chain.link/chainlink-functions/resources/subscriptions#create-a-subscriptio) and make a note of your subscription id. 
* Add the address as a consumer of your [Chainlink Functions](https://functions.chain.link/) subscription.
* Configure the CarbonLayer renewable energy threshold for your use case using setThreshold, e.g. `setThreshold(600)` sets a requirement for a 60% renewable energy source.
* Configure the standard and reduced fees using setFees, e.g. `setFees(2000000000000000, 1000000000000000)` sets a fee of 0.002 ETH and a reduced fee of 0.001 ETH.
