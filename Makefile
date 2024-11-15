-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL)
	--private-key $(PRIVATE_KEY) --broadcast --etherscan-api-key $(ETHERSCAN_APU_KEY) 
	-vvvv