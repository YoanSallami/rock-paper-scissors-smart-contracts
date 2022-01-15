async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    //const YankenpoFactory = await ethers.getContractFactory("YankenpoFactory");
    //const contractInstance = await YankenpoFactory.deploy();

    const YankenpoControl = await ethers.getContractFactory("YankenpoControl");
    const contractInstance = await YankenpoControl.deploy();
  
    console.log("Contract address:", contractInstance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  