## to deploy on base:
npx hardhat compile
npx hardhat run scripts/deploy.js --network base


## to verify:
change contract to the contract that gets deployed with the above
npx hardhat verify --network base 0xf0efd15800ba0a8d07c9952104d5613ec9a37b13