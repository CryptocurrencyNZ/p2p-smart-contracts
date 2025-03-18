const hre = require("hardhat");

async function main() {
  const P2PEscrow = await hre.ethers.getContractFactory("P2PCryptoEscrow");
  const escrow = await P2PEscrow.deploy();

  await escrow.waitForDeployment();
  console.log("P2P Escrow deployed to:", escrow.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
